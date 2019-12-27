
# Embed Fleetview Widget

## Setup

To get a custom Ship List on your Website you can just paste the example code on the right side at the position where you want to render a Ship List.

```html
<div id="fleetyards-view"></div>
<script>
    var fleetyards_config = function () {
        return {
            details: true, // Set to false if you want to display a minimal version of the Ship Panel
            grouped: true, // Set to false if you want to display the same Ships multiple times in your Fleetview.
            fleetchart: false, // Set to true if you want to display a Fleetchart instead of the normal Ship Panels.
            fleetchartGrouped: false, // Set to true if you want to group the Ships on the Fleetchart View or not.
            fleetchartScale: 50, // Initial Scale of the Fleetchart
            groupedButton: false, // Allow the User to toggle Groupped Views
            fleetchartSlider: false, // Set to true to display a slider which allows users to scale the Fleetchart
            ships: ['100i', '300i', '600i-touring', '890-jump'], // Replace the Array with a List of Shipnames (slugs) you want to display,
            users: ['torlekmaru', 'johndoe'], // Replace the Array with a list of Fleetyards.net usernames, alternative to the ships option.
        }
    };
    (function() {
        var d = document, s = d.createElement('script');
        s.src = 'https://fleetyards.net/embed.js#' + new Date().getTime();
        (d.head || d.body).appendChild(s);
    })();
</script>
<noscript>Please enable JavaScript to view your custom Fleetview powered by FleetYards.net.</a></noscript>
```

## Options

### Show Details

```details```: `true|false` (boolean) default is `true` 

Display details about the given Ship or just a minimal version. 

<br>

### Grouped View

```grouped```: `true|false` (boolean) default is `true` 

Group duplicated Ships and Show a count on each Ship Panel. 

<br>

### Render as Fleetchart

```fleetchart```: `true|false` (boolean) default is `false` 

Display the Fleetview as a Fleetchart with correct Ship Dimensions.

<br>

### Grouped View for Fleetchart

```fleetchartGrouped```: `true|false` (boolean) default is `false` 

Group duplicated Ships in the Fleetchart

<br>

### Initial Fleetchart Scale

```fleetchartScale```: `50` (int) default is `50` 

Set the initial Scale of the Fleetchart, can be between 10 - 300 for Desktop and 10 - 100 for Mobile.

<br>


### Show Fleetchart Slider

```fleetchartSlider```: `true|false` (boolean) default is `false` 

Display a slider to allow users to scale the Fleetchart.

<br>

### Ships List

```ships```: `[]` (Array of Strings) default is `[]`

The Fleetview expects a List of Shipnames (slugs). If you want to have Ships multiple times in the Fleetview just add them multiple times to the list.
To be able to resolve the correct Ships from the Fleetyards.net API you need to provide every Shipname (slug) in the correct Format.

You can use the Following Mapping to find out what the slug looks like for each Ship:

```json
{
    "100i": "100i",
    "125a": "125a",
    "135c": "135c",
    "300i": "300i",
    "315p": "315p",
    "325a": "325a",
    "350r": "350r",
    "600i Explorer": "600i-explorer",
    "600i Touring": "600i-touring",
    "85X": "85x",
    "890 Jump": "890-jump",
    "A2 Hercules": "a2-hercules",
    "Apollo Medivac": "apollo-medivac",
    "Apollo Triage": "apollo-triage",
    "Aurora CL": "aurora-cl",
    "Aurora ES": "aurora-es",
    "Aurora LN": "aurora-ln",
    "Aurora LX": "aurora-lx",
    "Aurora MR": "aurora-mr",
    "Avenger Stalker": "avenger-stalker",
    "Avenger Titan": "avenger-titan",
    "Avenger Titan Renegade": "avenger-titan-renegade",
    "Avenger Warlock": "avenger-warlock",
    "Blade": "blade",
    "Buccaneer": "buccaneer",
    "C2 Hercules": "c2-hercules",
    "Carrack": "carrack",
    "Caterpillar": "caterpillar",
    "Caterpillar Pirate Edition": "caterpillar-pirate-edition",
    "Constellation Andromeda": "constellation-andromeda",
    "Constellation Aquila": "constellation-aquila",
    "Constellation Phoenix": "constellation-phoenix",
    "Constellation Phoenix Emerald": "constellation-phoenix-emerald",
    "Constellation Taurus": "constellation-taurus",
    "Crucible": "crucible",
    "Cutlass Black": "cutlass-black",
    "Cutlass Blue": "cutlass-blue",
    "Cutlass Red": "cutlass-red",
    "Cyclone": "cyclone",
    "Cyclone-AA": "cyclone-aa",
    "Cyclone-RC": "cyclone-rc",
    "Cyclone-RN": "cyclone-rn",
    "Cyclone-TR": "cyclone-tr",
    "Defender": "defender",
    "Dragonfly Black": "dragonfly-black",
    "Dragonfly Starkitten Edition": "dragonfly-starkitten-edition",
    "Dragonfly Yellowjacket": "dragonfly-yellowjacket",
    "Eclipse": "eclipse",
    "Endeavor": "endeavor",
    "F7A Hornet": "f7a-hornet",
    "F7C Hornet": "f7c-hornet",
    "F7C Hornet Wildfire": "f7c-hornet-wildfire",
    "F7C-M Super Hornet": "f7c-m-super-hornet",
    "F7C-R Hornet Tracker": "f7c-r-hornet-tracker",
    "F7C-S Hornet Ghost": "f7c-s-hornet-ghost",
    "F8C": "f8c",
    "F8C Executive": "f8c-executive",
    "Freelancer": "freelancer",
    "Freelancer DUR": "freelancer-dur",
    "Freelancer MAX": "freelancer-max",
    "Freelancer MIS": "freelancer-mis",
    "Genesis Starliner": "genesis-starliner",
    "Geotack Planetary Beacon": "geotack-planetary-beacon",
    "Geotack-X Planetary Beacon": "geotack-x-planetary-beacon",
    "Gladiator": "gladiator",
    "Gladius": "gladius",
    "Gladius Valiant": "gladius-valiant",
    "Glaive": "glaive",
    "Hammerhead": "hammerhead",
    "Hawk": "hawk",
    "Herald": "herald",
    "Hull A": "hull-a",
    "Hull B": "hull-b",
    "Hull C": "hull-c",
    "Hull D": "hull-d",
    "Hull E": "hull-e",
    "Hurricane": "hurricane",
    "Idris-M": "idris-m",
    "Idris-P": "idris-p",
    "Javelin": "javelin",
    "Khartu-Al": "khartu-al",
    "M2 Hercules": "m2-hercules",
    "M50": "m50",
    "MPUV Cargo": "mpuv-cargo",
    "MPUV Personnel": "mpuv-personnel",
    "Merchantman": "merchantman",
    "Mustang Alpha": "mustang-alpha",
    "Mustang Beta": "mustang-beta",
    "Mustang Delta": "mustang-delta",
    "Mustang Gamma": "mustang-gamma",
    "Mustang Omega": "mustang-omega",
    "Nova Tank": "nova-tank",
    "Nox": "nox",
    "Nox Kue": "nox-kue",
    "Orion": "orion",
    "P52 Merlin": "p52-merlin",
    "P72 Archimedes": "p72-archimedes",
    "PTV": "ptv",
    "Pioneer": "pioneer",
    "Polaris": "polaris",
    "Prospector": "prospector",
    "Prowler": "prowler",
    "Razor": "razor",
    "Razor EX": "razor-ex",
    "Razor LX": "razor-lx",
    "Reclaimer": "reclaimer",
    "Redeemer": "redeemer",
    "Reliant Kore": "reliant-kore",
    "Reliant Mako": "reliant-mako",
    "Reliant Sen": "reliant-sen",
    "Reliant Tana": "reliant-tana",
    "Retaliator Base": "retaliator-base",
    "Retaliator Bomber": "retaliator-bomber",
    "Sabre": "sabre",
    "Sabre Comet": "sabre-comet",
    "Sabre Raven": "sabre-raven",
    "Scythe": "scythe",
    "Starfarer": "starfarer",
    "Starfarer Gemini": "starfarer-gemini",
    "Terrapin": "terrapin",
    "Ursa Rover": "ursa-rover",
    "Vanguard Harbinger": "vanguard-harbinger",
    "Vanguard Hoplite": "vanguard-hoplite",
    "Vanguard Sentinel": "vanguard-sentinel",
    "Vanguard Warden": "vanguard-warden",
    "Vulcan": "vulcan",
    "Vulture": "vulture",
    "X1 Base": "x1-base",
    "X1 Force": "x1-force",
    "X1 Velocity": "x1-velocity"
}
```

Please use https://www.fleetyards.net/ships or call the Fleetyards.net API ```/v1/models``` to fetch the latest Shipnames.

<br>

### Users List

```users```: `[]` (Array of Strings) default is `[]`

As an alternative to the Ships List you can also provide a list of Fleetyards usernames. You will than get a list of all Ships those Users have in there public Hangar.

<br>
