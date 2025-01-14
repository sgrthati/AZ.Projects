import os
import json
import requests

def lambda_handler(event, context):
    # Get SOAP endpoint and version from environment variables
    soap_url = os.environ.get("SOAP_ENDPOINT")
    soap_version = os.environ.get("SOAP_VERSION", "1.1")  # Default to SOAP 1.1
    
    # Extract REST method, headers, and payload
    rest_method = event.get("httpMethod", "POST")
    headers = event.get("headers", {})
    body = event.get("body", "")

    # Define SOAP namespace and content type based on version
    if soap_version == "1.2":
        soap_namespace = "http://www.w3.org/2003/05/soap-envelope"
        soap_content_type = "application/soap+xml"
    else:  # Default to SOAP 1.1
        soap_namespace = "http://schemas.xmlsoap.org/soap/envelope/"
        soap_content_type = "text/xml"

    # Transform REST to SOAP
    soap_request = f"""
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="{soap_namespace}">
        <SOAP-ENV:Body>
            <RESTMethod>{rest_method}</RESTMethod>
            <Payload>{body}</Payload>
        </SOAP-ENV:Body>
    </SOAP-ENV:Envelope>
    """
    
    soap_headers = {"Content-Type": soap_content_type}

    try:
        # Send SOAP request
        response = requests.post(soap_url, data=soap_request, headers=soap_headers)
        response.raise_for_status()

        # Transform SOAP response to REST response
        return {
            "statusCode": 200,
            "body": response.text,
            "headers": {"Content-Type": "application/json"},
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
            "headers": {"Content-Type": "application/json"},
        }
