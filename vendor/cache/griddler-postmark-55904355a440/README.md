# Griddler::Postmark

An adapter for [Griddler](https://github.com/thoughtbot/griddler) to allow
[Postmark](http://developer.postmarkapp.com/developer-inbound-parse.html) to be
used with the gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'griddler'
gem 'griddler-postmark'
```

## Usage

Create an initializer with the following settings:

```
Griddler.configure do |config|
  config.email_service = :postmark
end
```

Then configure Postmark to use the endpoint specified in Griddler's
docs.

## More Information

* [Postmark](http://postmarkapp.com)
* [Postmark Docs](http://developer.postmarkapp.com/)
