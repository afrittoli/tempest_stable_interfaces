from tempest.lib import auth


def get_auth_provider_class(credentials):
    if isinstance(credentials, auth.KeystoneV3Credentials):
        return auth.KeystoneV3AuthProvider, CONF.identity.uri_v3
    else:
        return auth.KeystoneV2AuthProvider, CONF.identity.uri


def get_auth_provider(credentials, pre_auth=False):
    default_params = {
        'disable_ssl_certificate_validation':
            CONF.identity.disable_ssl_certificate_validation,
        'ca_certs': CONF.identity.ca_certificates_file,
        'trace_requests': CONF.debug.trace_requests
    }
    auth_provider_class, auth_url = get_auth_provider_class(
        credentials)
    _auth_provider = auth_provider_class(credentials, auth_url,
                                         **default_params)
    if pre_auth:
        _auth_provider.set_auth()
    return _auth_provider