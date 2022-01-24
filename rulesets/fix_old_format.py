from jsonschema import validate, ValidationError
import json


if __name__ == "__main__":
    for file_name in ['full_256_7_part.json']:
        print("fixing: ", file_name)
        json_file = open(file_name)
        data = json.load(json_file)
        json_file.close()

        for i, tile in enumerate(data["tile_data"]):
            if "variant_rotations" in tile:
                del data["tile_data"][i]["variant_rotations"]
            if "generate_piece_indexes" in tile:
                data["tile_data"][i]["part_indexes"] = tile["generate_piece_indexes"].copy()
                del data["tile_data"][i]["generate_piece_indexes"]
            if "generate_piece_rotations" in tile:
                data["tile_data"][i]["part_rotations"] = tile["generate_piece_rotations"].copy()
                del data["tile_data"][i]["generate_piece_rotations"]
            if "generate_piece_flip_x" in tile:
                data["tile_data"][i]["part_flip_x"] = [bool(flip) for flip in tile["generate_piece_flip_x"]]
                del data["tile_data"][i]["generate_piece_flip_x"]
            if "generate_piece_flip_y" in tile:                
                data["tile_data"][i]["part_flip_y"] = [bool(flip) for flip in tile["generate_piece_flip_y"]]
                del data["tile_data"][i]["generate_piece_flip_y"]
        with open(file_name, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)

        


