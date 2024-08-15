import json
import logging
import os

import requests
from pydantic import BaseModel, model_validator

from humanlayer.core.models import (
    FunctionCall,
    FunctionCallStatus,
    HumanContact,
)
from humanlayer.core.protocol import (
    AgentBackend,
    AgentStore,
    HumanLayerException,
)

logger = logging.getLogger(__name__)


class HumanLayerCloudConnection(BaseModel):
    api_key: str | None = None
    api_base_url: str | None = None

    @model_validator(mode="after")
    def validate(self) -> None:
        self.api_key = self.api_key or os.getenv("HUMANLAYER_API_KEY")
        self.api_base_url = self.api_base_url or os.getenv(
            "HUMANLAYER_API_BASE", "https://api.humanlayer.dev/humanlayer/v1"
        )
        if not self.api_key:
            raise ValueError("HUMANLAYER_API_KEY is required for cloud approvals")

    def request(self, method: str, path: str, **kwargs):
        return requests.request(
            method,
            f"{self.api_base_url}{path}",
            headers={"Authorization": f"Bearer {self.api_key}"},
            timeout=10,
            **kwargs,
        )


class CloudFunctionCallStore(AgentStore[FunctionCall]):
    def __init__(self, connection: HumanLayerCloudConnection) -> None:
        self.connection = connection

    def add(self, item: FunctionCall) -> None:
        resp = self.connection.request(
            "POST",
            "/function_calls",
            json=item.model_dump(),
        )
        resp_json = resp.json()

        logger.debug("response %d %s", resp.status_code, json.dumps(resp_json, indent=2))

        if resp.status_code != 200:
            raise HumanLayerException(f"Error creating function call: {resp_json}")

    def get(self, call_id: str) -> FunctionCall:
        resp = self.connection.request(
            "GET",
            f"/function_calls/{call_id}",
        )
        resp_json = resp.json()
        logger.debug(
            "response %d %s",
            resp.status_code,
            json.dumps(resp_json, indent=2),
        )
        if resp.status_code != 200:
            raise HumanLayerException(f"Error fetching function call: {resp_json}")
        return FunctionCall.model_validate(resp_json)

    def respond(self, call_id: str, status: FunctionCallStatus) -> None:
        raise NotImplementedError()


class CloudHumanContactStore(AgentStore[HumanContact]):
    def __init__(self, connection: HumanLayerCloudConnection) -> None:
        self.connection = connection

    def add(self, item: HumanContact) -> None:
        resp = self.connection.request(
            "POST",
            "/contact_requests",
            json=item.model_dump(),
        )
        resp_json = resp.json()

        logger.debug("response %d %s", resp.status_code, json.dumps(resp_json, indent=2))

        if resp.status_code != 200:
            raise HumanLayerException(f"Error creating function call: {resp_json}")

    def get(self, call_id: str) -> HumanContact:
        resp = self.connection.request(
            "GET",
            f"/contact_requests/{call_id}",
        )
        resp_json = resp.json()
        logger.debug(
            "response %d %s",
            resp.status_code,
            json.dumps(resp_json, indent=2),
        )
        return HumanContact.model_validate(resp_json)


class CloudHumanLayerBackend(AgentBackend):
    def __init__(self, connection: HumanLayerCloudConnection) -> None:
        self.connection = connection
        self._function_calls = CloudFunctionCallStore(connection=connection)
        self._human_contacts = CloudHumanContactStore(connection=connection)

    def functions(self) -> CloudFunctionCallStore:
        return self._function_calls

    def contacts(self) -> CloudHumanContactStore:
        return self._human_contacts
