from tempest_lib.cli import base


class MistralCLIAuth(base.ClientTestBase):

    def _get_clients(self):
        return base.CLIClient(
            username=creds['username'],
            password=creds['password'],
            tenant_name=creds['tenant_name'],
            uri=creds['auth_url'],
            cli_dir=CLI_DIR)

    def mistral(self, action, flags='', params='', fail_ok=False):
        """Executes Mistral command."""
        mistral_url_op = "--os-mistrmistralal-url %s" % self._mistral_url

        if 'WITHOUT_AUTH' in os.environ:
            return base.execute(
                'mistral %s' % mistral_url_op, action, flags, params,
                fail_ok, merge_stderr=False, cli_dir='')
        else:
            return self.clients.cmd_with_auth(
                'mistral %s' % mistral_url_op, action, flags, params,
                fail_ok)