#these script is to responsible to deployable APIs in multi cloud environment
import os
import yaml
import argparse
import requests
import re

#OpenAPI Spec Generator

def generate_openapi_spec_azure(input_yaml):
    # Start creating the OpenAPI spec
    openapi_spec = {
        "openapi": "3.0.0",
        "info": {
            "title": input_yaml['API']['Name'],
            "description": input_yaml['API']['Description'],
            "version": input_yaml['API']['Version']
        },
        "servers": [],
        "paths": {},
        "components": {
            "schemas": dict(input_yaml['components']['schemas']),
            "securitySchemes": {}
        }
    }
    # Check if the backend URLs are present in the input YAML and generate servers array
    if 'Backend' in input_yaml:
        openapi_spec["servers"] = [{"url": url} for url in input_yaml['Backend']]
    else:
        openapi_spec["servers"] = [{"url": "https://example.com"}]  # Default server if not provided
    # Iterate over each path and create the corresponding OpenAPI paths
    for path in input_yaml['Paths']:
        path_name = path['Name']
        path_id = path['ID']
        path_info = path['Info']
        openapi_spec["paths"][path_name] = {}
        # Find placeholders in the path (e.g., {id}, {name})
        placeholders = re.findall(r'{(.*?)}', path_name)
        for operation in path['Operations'].split(','):
            operation = operation.strip().lower()  # Normalize operation to lowercase (get, post, etc.)
            
            # Check if the corresponding schema exists for this operation
            operation_schema_key = operation  # Schema key is lowercase (get, post, put, update)

            if operation_schema_key in input_yaml['components']['schemas']:
                # Add the operation to the OpenAPI spec with content block
                openapi_spec["paths"][path_name][operation] = {
                    "summary": path_info,
                    "parameters": [], 
                    "description": path_info,
                    "operationId": f"{path_id}_{operation}",
                    "responses": {
                        "200": {
                            "description": "Successful operation",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "$ref": f"#/components/schemas/{operation_schema_key}"
                                    }
                                }
                            }
                        },
                        "400": {
                            "description": "Bad request"
                        },
                        "500": {
                            "description": "Internal server error"
                        }
                    }
                }
                
            else:
                # If schema does not exist, add the operation without content block
                openapi_spec["paths"][path_name][operation] = {
                    "summary": path_info,
                    "description": path_info,
                    "operationId": f"{path_id}_{operation}",
                    "responses": {
                        "200": {
                            "description": "Created operation"
                        },
                        "400": {
                            "description": "Bad request"
                        },
                        "500": {
                            "description": "Internal server error"
                        }
                    }
                }
    # Add component schemas if they exist in the input YAML
    return openapi_spec
def write_openapi_spec_to_file(spec, output_file):
    os.makedirs(os.path.dirname(output_file), exist_ok=True)  # Create output folder if it doesn't exist
    with open(output_file, 'w') as f:
        yaml.dump(spec, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Generate OpenAPI Spec from YAML input.")
    parser.add_argument('--input-file', type=str, required=True, help="Path to the input YAML file.")
    parser.add_argument('--output-folder', type=str, required=True, help="Folder to save the output OpenAPI YAML file.")
    
    args = parser.parse_args()

    # Read input YAML file
    if not os.path.isfile(args.input_file):
        print(f"Error: Input file {args.input_file} does not exist or is not a valid file.")
        return

    with open(args.input_file, 'r') as f:
        input_yaml = yaml.safe_load(f)

    # Generate OpenAPI Spec
    openapi_spec = generate_openapi_spec_azure(input_yaml)

    # Generate output file path
    input_filename = os.path.basename(args.input_file)
    output_filename = input_filename.replace('.yaml', '-openapi.yaml')  # Create output filename
    output_file = os.path.join(args.output_folder, output_filename)

    # Write the OpenAPI spec to the output file
    write_openapi_spec_to_file(openapi_spec, output_file)
    print(f"OpenAPI specification has been generated and saved to {output_file}")

if __name__ == '__main__':
    main()