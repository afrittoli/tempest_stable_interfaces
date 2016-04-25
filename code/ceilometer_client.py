from tempest.lib.common import rest_client

# Use tempest base client manager
from tempest import manager
from tempest.services.image.v1.json.images_client import ImagesClient


class TelemetryClient(rest_client.RestClient):

    def create_sample(self, meter_name, sample_list):
        uri = "%s/meters/%s" % (self.uri_prefix, meter_name)
        body = self.serialize(sample_list)
        resp, body = self.post(uri, body)
        self.expected_success(200, resp.status)
        body = self.deserialize(body)
        return rest_client.ResponseBody(resp, body)


class Manager(manager.Manager):

    def set_image_client(self):
        self.image_client = ImagesClient(self.auth_provider,
                                         **self.image_params)

    def set_telemetry_client(self):
        self.telemetry_client = TelemetryClient(self.auth_provider,
                                                **self.telemetry_params)