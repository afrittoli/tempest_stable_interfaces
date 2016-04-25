from tempest.lib.common import api_version_utils
import tempest.test


class BaseV2ComputeTest(api_version_utils.BaseMicroversionTest,
                        tempest.test.BaseTestCase):

    @classmethod
    def skip_checks(cls):
        super(BaseV2ComputeTest, cls).skip_checks()
        if not CONF.service_available.nova:
            raise cls.skipException("Nova is not available")
        cfg_min_version = CONF.compute.min_microversion
        cfg_max_version = CONF.compute.max_microversion
        api_version_utils.check_skip_with_microversion(cls.min_microversion,
                                                       cls.max_microversion,
                                                       cfg_min_version,
                                                       cfg_max_version)

    @classmethod
    def resource_setup(cls):
        super(BaseV2ComputeTest, cls).resource_setup()
        cls.request_microversion = (
            api_version_utils.select_request_microversion(
                cls.min_microversion,
                CONF.compute.min_microversion))