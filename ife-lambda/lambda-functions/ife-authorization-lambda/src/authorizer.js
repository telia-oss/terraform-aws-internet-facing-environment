console.log('Loading function');

const userPoolId = process.env.USER_POOL_ID;
const region = process.env.REGION; //e.g. us-east-1
const iss = 'https://cognito-idp.' + region + '.amazonaws.com/' + userPoolId;

const { bearerAuth } = require('./bearerAuth.js');
const { basicAuth } = require('./basicAuth.js');

exports.handler = async (event, context) => {

    try {
        let authorizationHeader = event.authorizationToken;

        if (authorizationHeader.startsWith("Bearer ")) {
            let token = authorizationHeader.split(' ')[1]
            return bearerAuth(token, iss, event);
        } else if (authorizationHeader.startsWith("Basic ")) {
            let token = authorizationHeader.split(' ')[1]
            return basicAuth(token, event);
        } else {
            throw "Unauthorized";
        }
    } catch (e) {
        throw e;
    }
};
