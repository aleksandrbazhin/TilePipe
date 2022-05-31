
## Roadmap for the 2.0 release

- In the tile main view: highlight what parts are used
- Generation start logic (On every change basically. Now it's only tied to the change in the sliders)
- Randomization
- Output settings use in generation
- Ruleset validity checks
- New tile creation UI
- Migrate all the examples
- Result preview: show one enlarged subtile in the left rectangle
- Add Godot export
- All-in-one folder-project export
- Testing and fixes
- Docs

# TilePipe2
## Tilepipe is autotiling tileset generator

The project is meant to be a part of the artist pipeline when creating 2D tilesets for game development. Instead of 47 or 255 tiles you can draw only a couple of parts (like corners) that differ and have everything else generated.
 
This is the second iteration of the project, here's the origina; TilePipe project page on itch.io https://aleksandrbazhin.itch.io/tilepipe. It's source can be found in the respectale git branch.

## About tiling in general



## Using TilePipe2
### Glossary
- Tileset
- Tile
- Subtile
- Ruleset
- Template

### Basic usage as example
### Creating your own tiles
- Input texture
- Template
- Ruleset
- Exporting







## Motivation behind the TilePipe2
1. Perfectionism
2. Ability to save and use custom rulesets (previously named presets). These are now json files, schema is included in the project. There is a viewer in the GUI.
3. Project-like logic for every directory. Several tile sources now from a project, which can be exported at once.
4. Every data is now explicit, there is minimal built-in logic (not examples, not templates, not rulesets). It's a VCS-ready approach, all the cahnges are now trackable. Everything previously built-in os now distributed as the examples.


## Screens
Tile main view (overview)
![Tile overview (unfinished)](Screen1.png)
Ruleset viewer
![Ruleset (unfinished)](Screen2.png)
Texture setup
![Texture settings (unfinished)](Screen3.png)


## Roadmap for the future
- Setup tile input - where to get the numbered parts. That way it will be possible to use existing tilesets like rpgmaker ones.
- Rotated tiles - for isometric tilesets
- Rectangle tiles (not square) 
- Animation export (side by side tiles blocks)
- Export the entire directory as a project at once
- Export to Tiled (https://www.mapeditor.org/)
- Ruleset GUI editor
- Template GUI editor
- Shader-based effects on tile merges
- Rebuild Godot export presets for optimized export