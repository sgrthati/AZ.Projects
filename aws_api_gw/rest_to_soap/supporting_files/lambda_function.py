import os
import json
import requests
from xml.etree import ElementTree

def lambda_handler(event, context):
    # Get SOAP endpoint and version from environment variables
    soap_url = os.environ.get("SOAP_ENDPOINT")
    soap_version = os.environ.get("SOAP_VERSION", "1.1")  # Default to SOAP 1.1

    # Extract REST method, headers, and payload
    body = event.get("body", "{}")  # Assume JSON payload from REST call
    rest_payload = json.loads(body) if body else {}

    # Define SOAP namespace, content type, and envelope prefix based on version
    if soap_version == "1.2":
        soap_namespace = "http://www.w3.org/2003/05/soap-envelope"
        soap_content_type = "application/soap+xml"
        soap_prefix = "soap12"
    else:  # Default to SOAP 1.1
        soap_namespace = "http://schemas.xmlsoap.org/soap/envelope/"
        soap_content_type = "text/xml"
        soap_prefix = "soap"

    # Dynamically construct the SOAP body based on the payload
    if "Celsius" in rest_payload:
        operation = "CelsiusToFahrenheit"
        parameter = "Celsius"
        value = rest_payload["Celsius"]
    elif "Fahrenheit" in rest_payload:
        operation = "FahrenheitToCelsius"
        parameter = "Fahrenheit"
        value = rest_payload["Fahrenheit"]
    else:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid payload. Must include 'Celsius' or 'Fahrenheit'."}),
            "headers": {"Content-Type": "application/json"},
        }

    # Transform REST to SOAP
    soap_request = f"""
    <{soap_prefix}:Envelope xmlns:{soap_prefix}="{soap_namespace}" xmlns:tem="https://www.w3schools.com/xml/">
        <{soap_prefix}:Body>
            <tem:{operation}>
                <tem:{parameter}>{value}</tem:{parameter}>
            </tem:{operation}>
        </{soap_prefix}:Body>
    </{soap_prefix}:Envelope>
    """

    soap_headers = {"Content-Type": soap_content_type}

    try:
        # Send SOAP request
        response = requests.post(soap_url, data=soap_request, headers=soap_headers)
        response.raise_for_status()

        # Parse SOAP response
        root = ElementTree.fromstring(response.text)
        namespace = {"soap": soap_namespace, "tem": "https://www.w3schools.com/xml/"}
        result = root.find(f".//tem:{operation}Result", namespace)

        if result is not None:
            # Format SOAP response into JSON
            formatted_response = {
                "operation": operation,
                "input": {parameter: value},
                "output": {f"{operation}Result": result.text}
            }
            return {
                "statusCode": 200,
                "body": json.dumps(formatted_response, indent=2),
                "headers": {"Content-Type": "application/json"},
            }
        else:
            return {
                "statusCode": 500,
                "body": json.dumps({"error": "Could not parse SOAP response"}),
                "headers": {"Content-Type": "application/json"},
            }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
            "headers": {"Content-Type": "application/json"},
        }