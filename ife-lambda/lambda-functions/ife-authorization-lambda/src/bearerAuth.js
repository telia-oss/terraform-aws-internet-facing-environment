var jwt = require('jsonwebtoken');
var request = require('request');
var jwkToPem = require('jwk-to-pem');

const { isResourceAllowed } = require('./authUtils.js');
const { AuthPolicy } = require('./authUtils.js');

var pems;

async function bearerAuth(token, iss, event) {

    //Download PEM for your UserPool if not already downloaded
    if (!pems) {
        //Download the JWKs and save it as PEM
        let body = await getPemFromPool(iss);

        pems = {};
        var keys = body['keys'];
        for (var i = 0; i < keys.length; i++) {
            //Convert each key to PEM
            var key_id = keys[i].kid;
            var modulus = keys[i].n;
            var exponent = keys[i].e;
            var key_type = keys[i].kty;
            var jwk = { kty: key_type, n: modulus, e: exponent };
            var pem = jwkToPem(jwk);
            pems[key_id] = pem;
        }
    }

    return await ValidateToken(pems, token, iss, event);
}


//Download the JWKs and save it as PEM
const getPemFromPool = (iss) => {
    return new Promise((resolve, reject) => {
        request({
            url: iss + '/.well-known/jwks.json',
            json: true
        }, function (error, response, body) {
            if (!error && response.statusCode === 200) {
                try {
                    resolve(body);
                } catch (e) {
                    reject(e);
                }
            } else //Unable to download JWKs, fail the call
                reject("error");
        });
    });
}

async function ValidateToken(pems, token, iss, event) {

    //Fail if the token is not jwt
    var decodedJwt = jwt.decode(token, { complete: true });
    if (!decodedJwt) {
        console.log("Not a valid JWT token");
        throw "Unauthorized";
    }

    //Fail if token is not from your UserPool
    if (decodedJwt.payload.iss != iss) {
        console.log("invalid issuer");
        throw "Unauthorized";
    }

    //Reject the jwt if it's not an 'Access Token'
    if (decodedJwt.payload.token_use != 'access') {
        console.log("Not an access token");
        throw "Unauthorized";
    }

    //Get the kid from the token and retrieve corresponding PEM
    var kid = decodedJwt.header.kid;
    var pem = pems[kid];
    if (!pem) {
        console.log('Invalid access token');
        throw "Unauthorized";
    }

    return new Promise(function (resolve, reject) {
        //Verify the signature of the JWT token to ensure it's really coming from your User Pool
        jwt.verify(token, pem, { issuer: iss }, function (err, payload) {
            if (err) {
                reject("Unauthorized");
            } else {
                //Valid token. Generate the API Gateway policy for the user
                //Always generate the policy on value of 'sub' claim and not for 'username' because username is reassignable
                //sub is UUID for a user which is never reassigned to another user.
                var principalId = payload.sub;

                //Get AWS AccountId and API Options
                var apiOptions = {};
                var tmp = event.methodArn.split(':');
                var apiGatewayArnTmp = tmp[5].split('/');
                var awsAccountId = tmp[4];
                apiOptions.region = tmp[3];
                apiOptions.restApiId = apiGatewayArnTmp[0];
                apiOptions.stage = apiGatewayArnTmp[1];
                var method = apiGatewayArnTmp[2];
                var resource = '/'; // root resource
                if (apiGatewayArnTmp[3]) {
                    resource += apiGatewayArnTmp[3];
                }

                //For more information on specifics of generating policy, refer to blueprint for API Gateway's Custom authorizer in Lambda console
                var policy = new AuthPolicy(principalId, awsAccountId, apiOptions);
                if (isResourceAllowed(resource, payload.scope)) {
                    policy.allowAllMethods();
                    resolve(policy.build());
                } else {
                    policy.denyAllMethods();
                    resolve(policy.build());
                }
            }
        });
    });

}


module.exports = { bearerAuth }
