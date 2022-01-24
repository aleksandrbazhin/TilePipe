from jsonschema import validate, ValidationError
import json


def validate_files():
    schema_file = open('ruleset_schema.json')
    schema = json.load(schema_file)
    schema_file.close()

    is_ok = True

    for file_name in ['basic_4_part.json', 'sideview_8_part.json', 'no_symmetry_13_part.json', 'full_256_7_part.json']:
        json_file = open(file_name)
        data = json.load(json_file)
        json_file.close()

        try:
            validate(instance=data,  schema=schema)
        except ValidationError as e:
            is_ok = False
            print( "Error validating \"" + file_name + "\":\n" + e.message + "\nPath in json:\n" + e.json_path)
    if is_ok:
        print("All rulesets are validated: OK")


if __name__ == "__main__":
    validate_files()

