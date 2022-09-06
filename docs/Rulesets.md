Here is the json schema for a ruleset: [ruleset_schema.json](/src/utils/ruleset_schema.json):

# TilePipe Ruleset

*Ruleset for tile generation used by TilePipe software*

## Properties

- **`ruleset_name`** *(string)*: Ruleset name.
- **`ruleset_description`** *(string)*: Ruleset descriprion.
- **`tile_parts`** *(array)*: Tile parts used to construct a tile as an array of string constants describing part role. There are 13 possible part roles. First one should always be 'FULL'. This is needed to know how exactly a part will combine with neighboring tile parts inside a subtile.
  - **Items** *(string)*: Must be one of: `['FULL', 'CORNER_IN_TOP_RIGHT', 'SIDE_TOP', 'CORNER_OUT_TOP_RIGHT', 'SIDE_RIGHT', 'CORNER_IN_BOTTOM_RIGHT', 'SIDE_BOTTOM', 'CORNER_OUT_BOTTOM_RIGHT', 'CORNER_OUT_BOTTOM_LEFT', 'CORNER_IN_BOTTOM_LEFT', 'CORNER_OUT_BOTTOM_LEFT', 'SIDE_LEFT', 'CORNER_OUT_TOP_LEFT', 'CORNER_IN_TOP_LEFT']`.
- **`tiles`** *(array)*
  - **Items** *(object)*
    - **`mask_variants`** *(array)*
      - **Items** *(integer)*: 8-bit mask describing tile neighbours, neighbours are checked clockwise starting from the top direction. Minimum: `0`. Maximum: `256`.
    - **`part_indexes`** *(array)*
      - **Items** *(integer)*: What input parts to take to use in specified positions. The length is always 8, parts are place clockwise starting from the top direction. Maximum should not be grater than the length of Input parts array. Minimum: `0`.
    - **`part_rotations`** *(array)*
      - **Items** *(integer)*: How many times the input part is rotated on placement. Each rotation is 90 degrees clockwise. From 0 to 3. Minimum: `0`. Maximum: `3`.
    - **`part_flip_x`** *(array)*
      - **Items** *(boolean)*: If the input part is flipped on placement over the X-axis.
    - **`part_flip_y`** *(array)*
      - **Items** *(boolean)*: If the input part is flipped on placement over the Y-axis.
