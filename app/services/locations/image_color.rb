# frozen_string_literal: true

module Locations
  # The colour a body's picture is mostly painted in, as a hex code, for the
  # circle it is drawn with. A planet render is a lit disc on black space, so
  # the near-black and near-white pixels are left out of the average: space
  # and the specular glare would pull every planet towards grey.
  class ImageColor
    SAMPLE_SIZE = 48
    DARKEST = 28
    BRIGHTEST = 240
    LIGHTNESS = (0.42..0.62)
    SATURATION_BOOST = 1.35

    def initialize(blob)
      @blob = blob
    end

    def call
      require "vips"

      @blob.open do |file|
        pixels = sample(Vips::Image.thumbnail(file.path, SAMPLE_SIZE))
        lit = pixels.select { |pixel| (DARKEST..BRIGHTEST).cover?(luma(pixel)) }
        lit = pixels if lit.empty?

        format("#%02x%02x%02x", *tone(average(lit))) if lit.any?
      end
    rescue Vips::Error, ActiveStorage::FileNotFoundError
      nil
    end

    # RGB triples, without the pixels an alpha channel makes transparent.
    private def sample(image)
      image = image.colourspace(:srgb) unless image.interpretation == :srgb
      rows = image.cast(:uchar).to_a
      pixels = rows.flatten(1)

      return pixels.map { |pixel| pixel.first(3) } if image.bands < 4

      pixels.select { |pixel| pixel[3] >= 128 }.map { |pixel| pixel.first(3) }
    end

    private def luma((red, green, blue))
      (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    end

    # Weighted by saturation, so a planet's tint wins over the grey of its
    # shadow side and haze: a plain mean turns Hurston beige-grey.
    private def average(pixels)
      weights = pixels.map { |pixel| saturation(pixel) + 0.05 }
      total = weights.sum

      3.times.map do |channel|
        (pixels.each_with_index.sum { |pixel, index| pixel[channel] * weights[index] } / total).round
      end
    end

    # The shading draws the light and the shadow itself, so the colour is
    # brought to a mid lightness and given back some of the saturation the
    # average took: Hurston reads as Hurston rather than as dusk.
    private def tone(rgb)
      hue, sat, light = hsl(rgb)

      rgb_from_hsl(hue, [sat * SATURATION_BOOST, 1.0].min, light.clamp(LIGHTNESS.min, LIGHTNESS.max))
    end

    private def hsl(rgb)
      red, green, blue = rgb.map { |value| value / 255.0 }
      high, low = [red, green, blue].max, [red, green, blue].min
      light = (high + low) / 2
      return [0.0, 0.0, light] if high == low

      delta = high - low
      sat = (light > 0.5) ? delta / (2 - high - low) : delta / (high + low)
      hue = case high
      when red then ((green - blue) / delta) % 6
      when green then ((blue - red) / delta) + 2
      else ((red - green) / delta) + 4
      end

      [hue * 60, sat, light]
    end

    private def rgb_from_hsl(hue, sat, light)
      chroma = (1 - ((2 * light) - 1).abs) * sat
      second = chroma * (1 - (((hue / 60) % 2) - 1).abs)
      base = light - (chroma / 2)

      red, green, blue = case hue
      when 0...60 then [chroma, second, 0]
      when 60...120 then [second, chroma, 0]
      when 120...180 then [0, chroma, second]
      when 180...240 then [0, second, chroma]
      when 240...300 then [second, 0, chroma]
      else [chroma, 0, second]
      end

      [red, green, blue].map { |value| ((value + base) * 255).round.clamp(0, 255) }
    end

    private def saturation(pixel)
      high, low = pixel.max, pixel.min
      high.zero? ? 0.0 : (high - low) / high.to_f
    end
  end
end
