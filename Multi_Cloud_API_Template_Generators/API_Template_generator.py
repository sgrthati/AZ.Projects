#these script is to responsible to deployable APIs in multi cloud environment
import os
import yaml
import argparse
import re
from xml.etree.ElementTree import Element, SubElement, tostring

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
                    "parameters": [
                        {
                            "name": placeholder,
                            "in": "path",
                            "required": True,
                            "schema": {
                                "type": "string"
                            },
                            "description": f"Parameter for {placeholder}"
                        }
                        for placeholder in placeholders
                    ],        
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
                    "parameters": [
                        {
                            "name": placeholder,
                            "in": "path",
                            "required": True,
                            "schema": {
                                "type": "string"
                            },
                            "description": f"Parameter for {placeholder}"
                        }
                        for placeholder in placeholders
                    ], 
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
def write_openapi_spec_to_file(spec, azure_openspc_output_file):
    os.makedirs(os.path.dirname(azure_openspc_output_file), exist_ok=True)  # Create output folder if it doesn't exist
    with open(azure_openspc_output_file, 'w') as f:
        yaml.dump(spec, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

#Azure API Policy Generator
def generate_backend_policy(input_yaml):
    # Initialize the root <inbound> policy element
    policy_root = Element('policies')

    # Create the <inbound> section for the backend policy
    inbound_policy = SubElement(policy_root, 'inbound')

    # Check if 'Backend' URLs are provided in the input YAML
    if 'Backend' in input_yaml:
        backend_urls = input_yaml['Backend']
        for url in backend_urls:
            # Apply the set-backend-service policy for each backend URL
            set_backend_service = SubElement(inbound_policy, 'set-backend-service')
            set_backend_service.set('base-url', f"{url}")
            # Optionally, you can add headers or other authentication methods
            # set_backend_service.set('authentication', 'Basic')
            # set_backend_service.set('username', 'username')
            # set_backend_service.set('password', 'password')

    else:
        # If no backend URL is provided, apply a default one
        set_backend_service = SubElement(inbound_policy, 'set-backend-service')
        set_backend_service.set('base-url', 'https://default-backend.com')
     # Add Quota policy if defined in YAML
    if 'Quota' in input_yaml:
        quota_policy = SubElement(inbound_policy, 'quota')
        quota_policy.set('calls', str(input_yaml['Quota']['calls']))  # Max number of calls
        quota_policy.set('bandwidth', input_yaml['Quota']['bandwidth'])  # Interval for the quota (e.g., "minute", "hour")
        quota_policy.set('renewal-period', str(input_yaml['Quota']['renewal-period']))  # Time window for the quota in seconds

    # Add Rate Limit policy if defined in YAML
    if 'RateLimit' in input_yaml:
        rate_limit_policy = SubElement(inbound_policy, 'rate-limit-by-key')
        rate_limit_policy.set('calls', str(input_yaml['RateLimit']['calls'])) 
        rate_limit_policy.set('renewal-period', str(input_yaml['RateLimit']['period']))
        rate_limit_policy.set('increment-condition', "@(context.Response.StatusCode == 200)")
        rate_limit_policy.set('counter-key', "@(context.request.key)")
    # Convert the XML tree to string for output
    return tostring(policy_root, encoding='unicode', method='xml')

# Function to write the generated policy to an XML file
def write_backend_policy_to_file(policy, apim_policy):
    os.makedirs(os.path.dirname(apim_policy), exist_ok=True)  # Create output folder if it doesn't exist
    with open(apim_policy, 'w') as f:
        f.write(policy)

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
    #Create a Folder    
    Azure_Dir = os.path.join(args.output_folder, "Azure")
    # Generate OpenAPI Spec
    openapi_spec = generate_openapi_spec_azure(input_yaml)

    # Generate output file path
    output_filename = f"{input_yaml['API']['Name']}-OpenAPI-Azure.yaml" # Create output filename
    azure_openspc_output_file = os.path.join(Azure_Dir, output_filename)

    # Write the OpenAPI spec to the output file
    write_openapi_spec_to_file(openapi_spec, azure_openspc_output_file)
    print(f"OpenAPI specification has been generated and saved to {azure_openspc_output_file}")
    
    # Generate Azure API Policy
    policy = generate_backend_policy(input_yaml)
    apim_policy = os.path.join(Azure_Dir, f"{input_yaml['API']['Name']}api-policy-Azure.xml")
    write_backend_policy_to_file(policy, apim_policy)
    print(f"API Policy has been generated and saved to {apim_policy}")

if __name__ == '__main__':
    main()