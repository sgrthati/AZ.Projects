#python script will create required JWK and Tocken,public&private.pem
#python gen_keys.py >> tokens.txt
#create a variable 'token' with generated JWT
#and execute below command
#for external_ip: external_ip=$(kubectl get svc -n istio-system -l app=istio-ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}')
#test: curl -H "Authorization: Bearer $token" http://$external_ip/hello


import json
import jwt
import datetime
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend
from jwcrypto import jwk

# Generate RSA private key
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
    backend=default_backend()
)

# Serialize the private key to PEM format
private_pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

# Extract the public key
public_key = private_key.public_key()

# Serialize the public key to PEM format
public_pem = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
)

# Convert the public key to JWK format
public_jwk = jwk.JWK.from_pem(public_pem)
public_jwk_dict = json.loads(public_jwk.export_public())

# Create a JWT
payload = {
    "iss": "issuer",
    "sub": "subject",
    "aud": "audience",
}

private_key_for_jwt = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

token = jwt.encode(payload, private_key_for_jwt, algorithm="RS256")

# Print the results
print("Private Key (PEM):")
print(private_pem.decode('utf-8'))
print("\nPublic Key (PEM):")
print(public_pem.decode('utf-8'))
print("\nPublic Key (JWK):")
print(json.dumps(public_jwk_dict, indent=4))
print("\nJWT:")
print(token)