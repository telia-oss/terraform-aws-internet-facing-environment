const { SSMClient, GetParameterCommand } = require('@aws-sdk/client-ssm');
const ssmClient = new SSMClient();

const { isResourceAllowed } = require('./authUtils.js');
const { AuthPolicy } = require('./authUtils.js');

const paramStorePrefix = '/' + process.env.PARAM_STORE_PREFIX + '/client/'

async function basicAuth(token, event) {

    const credentials = Buffer.from(token, 'base64').toString().split(':');
    const clientId = credentials[0];
    const password = credentials[1];

    const client = await getClientFromParamStore(clientId);
    const clientDetails = JSON.parse(client.Parameter.Value);

    checkClientPassword(password, clientDetails.password)

    const apiOptions = {};
    const tmp = event.methodArn.split(':');
    const awsAccountId = tmp[4]
    const apiGatewayArnTmp = tmp[5].split('/');
    let resource = '/'; // root resource
    if (apiGatewayArnTmp[3]) {
        resource += apiGatewayArnTmp[3];
    }

    const policy = new AuthPolicy(clientId, awsAccountId, apiOptions);
    if (isResourceAllowed(resource, clientDetails.allowed_scopes)) {
        policy.allowAllMethods();
        return policy.build();
    } else {
        policy.denyAllMethods();
        return policy.build();
    }

}

const getClientFromParamStore = async (clientId) => {
    let params = {
        Name: paramStorePrefix + clientId,
        WithDecryption: true
    }
    try {
        const command = new GetParameterCommand(params);
        return await ssmClient.send(command);
    } catch (err) {
        console.error(err);
        throw "Unauthorized";
    }
}

const checkClientPassword = (password, clientPassword) => {
    if (password !== clientPassword) {
        throw "Unauthorized"
    }
}

module.exports = { basicAuth }
