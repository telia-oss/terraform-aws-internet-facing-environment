let jwt = require('jsonwebtoken');
let request = require('request');
let jwkToPem = require('jwk-to-pem');

const { isResourceAllowed } = require('./authUtils.js');
const { AuthPolicy } = require('./authUtils.js');

let pems;

async function bearerAuth(token, iss, event) {

    //Download PEM for your UserPool if not already downloaded
    if (!pems) {
        //Download the JWKs and save it as PEM
        let body = await getPemFromPool(iss);

        pems = {};
        let keys = body['keys'];
        for (let i = 0; i < keys.length; i++) {
            //Convert each key to PEM
            let key_id = keys[i].kid;
            let modulus = keys[i].n;
            let exponent = keys[i].e;
            let key_type = keys[i].kty;
            let jwk = { kty: key_type, n: modulus, e: exponent };
            let pem = jwkToPem(jwk);
            pems[key_id] = pem;
        }
    }

    return await validateToken(pems, token, iss, event);
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

async function validateToken(pems, token, iss, event) {

    //Fail if the token is not jwt
    let decodedJwt = jwt.decode(token, { complete: true });
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
    let kid = decodedJwt.header.kid;
    let pem = pems[kid];
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
                let principalId = payload.sub;

                //Get AWS AccountId and API Options
                let apiOptions = {};
                let tmp = event.methodArn.split(':');
                let apiGatewayArnTmp = tmp[5].split('/');
                let awsAccountId = tmp[4];
                apiOptions.region = tmp[3];
                apiOptions.restApiId = apiGatewayArnTmp[0];
                apiOptions.stage = apiGatewayArnTmp[1];
                let method = apiGatewayArnTmp[2];
                let resource = '/'; // root resource
                if (apiGatewayArnTmp[3]) {
                    resource += apiGatewayArnTmp[3];
                }

                //For more information on specifics of generating policy, refer to blueprint for API Gateway's Custom authorizer in Lambda console
                let policy = new AuthPolicy(principalId, awsAccountId, apiOptions);
                if (isResourceAllowed(resource, payload.scope)) {
                    policy.allowAllMethods();
                    console.log("Bearer auth policy allowed!");
                    resolve(policy.build());
                } else {
                    policy.denyAllMethods();
                    console.log("Bearer auth policy denied!");
                    resolve(policy.build());
                }
            }
        });
    });

}


module.exports = { bearerAuth }
