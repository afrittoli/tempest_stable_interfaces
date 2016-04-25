# Import config for `register_opt_group`
from tempest import config
# Import the plugin base class
from tempest.test_discover import plugins

from manila_tempest_tests import config as config_share


class ManilaTempestPlugin(plugins.TempestPlugin):

    def register_opts(self, conf):
        config.register_opt_group(
            conf, config_share.service_available_group,
            config_share.ServiceAvailableGroup)
        config.register_opt_group(conf, config_share.share_group,
                                  config_share.ShareGroup)
