<template>
  <div class="bx--grid bx--grid--full-width">
    <div class="bx--row">
      <div class="bx--col-lg-16 page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </div>
    </div>
    <div v-if="error.getConfiguration" class="bx--row">
      <div class="bx--col">
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </div>
    </div>
    <div class="bx--row">
      <div class="bx--col-lg-16">
        <cv-tile :light="true">
          <cv-form @submit.prevent="saveSettings">
            <div v-if="error.configureModule" class="bx--row">
              <div class="bx--col">
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </div>
            </div>
            <cv-text-input
              :label="$t('settings.host')"
              :placeholder="$t('settings.host_placeholder')"
              v-model.trim="host"
              class="mg-bottom"
              :invalid-message="$t(error.host)"
              :disabled="loadingUi"
              ref="host"
            >
            </cv-text-input>
             <NsTextInput
              :label="$t('settings.admin_password')"
              type="password"
              v-model.trim="password"
              v-if="!installed"
              class="mg-bottom"
              :invalid-message="$t(error.password)"
              :disabled="loadingUi"
              ref="password"
            >
              <template slot="tooltip">
                <span>{{ $t("settings.admin_password_tooltip") }}</span>
              </template>
            </NsTextInput>
            <cv-toggle
              value="letsEncrypt"
              :label="$t('settings.lets_encrypt')"
              v-model="isLetsEncryptEnabled"
              :disabled="loadingUi"
              class="mg-bottom"
            >
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </cv-toggle>
            <NsComboBox
              v-model="domain"
              :options="domains"
              auto-highlight
              :title="$t('settings.domain')"
              :invalid-message="$t(error.listUserDomains)"
              :disabled="loadingUi"
              :label="$t('settings.choose_ldap_domain')"
              light
              tooltipAlignment="start"
              tooltipDirection="top"
              ref="domain"
            >
            </NsComboBox>
            <template v-if="is_collabora && installed">
              <NsComboBox
                v-model.trim="collabora_host"
                :autoFilter="true"
                :autoHighlight="true"
                :title="$t('settings.collabora_host')"
                :label="$t('settings.collabora_placeholder')"
                :options="collabora_URL"
                :userInputLabel="core.$t('common.user_input_l')"
                :acceptUserInput="false"
                :showItemType="true"
                :invalid-message="$t(error.collabora_host)"
                :disabled="loadingUi"
                tooltipAlignment="start"
                tooltipDirection="top"
                light
                ref="host"
              >
                <template slot="tooltip">
                {{
                  $t("settings.collabora_host_tooltip")
                }}
                </template>
              </NsComboBox>
              <cv-toggle
                value="tls_verify_collabora"
                :label="$t('settings.tls_verify_collabora')"
                v-model="tls_verify_collabora"
                :disabled="loadingUi"
                class="mg-bottom"
              >
                <template slot="text-left">{{
                  $t("settings.disabled")
                }}</template>
                <template slot="text-right">{{
                  $t("settings.enabled")
                }}</template>
              </cv-toggle>
            </template>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loadingUi"
              class="mg-top-md"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </div>
    </div>
  </div>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [TaskService, IconService, UtilService, QueryParamService],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      loading: {
        getConfiguration: true,
        configureModule: false,
        listUserDomains: true,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        listUserDomains: "",
        collabora_host: "",
        password: "",
        host: ""
      },
      style: {
        lowContrast: false,
        hideClose: true,
      },
      host: "",
      isLetsEncryptEnabled: false,
      domain: "",
      password: "Nethesis,1234",
      domains: [],
      collabora_URL: [],
      installed: false,
      running: false,
      is_collabora: false,
      tls_verify_collabora: true,
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    loadingUi() {
      return (
        this.loading.getConfiguration ||
        this.loading.listUserDomains ||
        this.loading.configureModule
      );
    },
  },
  created() {
    this.getConfiguration();
    this.listUserDomains();
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  methods: {
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";

      // register to task error
      this.core.$root.$off(taskAction + "-aborted");
      this.core.$root.$once(
        taskAction + "-aborted",
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$off(taskAction + "-completed");
      this.core.$root.$once(
        taskAction + "-completed",
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
          },
        })
      );
      const err = res[0];
      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.core.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    async listUserDomains() {
      this.loading.listUserDomains = true;
      this.error.listUserDomains = "";
      const taskAction = "list-user-domains";

      // register to task error
      this.core.$root.$off(taskAction + "-aborted");
      this.core.$root.$once(
        taskAction + "-aborted",
        this.listUserDomainsAborted
      );

      // register to task completion
      this.core.$root.$off(taskAction + "-completed");
      this.core.$root.$once(
        taskAction + "-completed",
        this.listUserDomainsCompleted
      );

      const res = await to(
        this.createClusterTaskForApp({
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
          },
        })
      );
      const err = res[0];
      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.listUserDomains = this.getErrorMessage(err);
        this.loading.listUserDomains = false;
        return;
      }
    },
    listUserDomainsAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.core.$t("error.generic_error");
      this.loading.listUserDomains = false;
    },
    validateSaveSettings() {
      this.clearErrors(this);
      let isValidationOk = true;
      if (!this.host) {
        // test field cannot be empty
        this.error.host = this.$t("common.required");
        this.focusElement("host");
        isValidationOk = false;
      }
      if (!this.domain) {
        // test field cannot be empty
        this.error.listUserDomains = this.$t("common.required");
        this.focusElement("domain");
        isValidationOk = false;
      }
      if (!this.password) {
        // test field cannot be empty
        this.error.password = this.$t("common.required");
        this.focusElement("password");
        isValidationOk = false;
      }
      // exclude characters not correctly supported by env file
      const re = new RegExp("\"|=|'|\\s|\\t");
      if (re.test(this.password)) {
        this.error.password = this.$t("error.password_invalid_chars");
        this.focusElement("password");
        isValidationOk = false;
      }
      return isValidationOk;
    },
    saveSettingsValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        // set i18n error message
        this.error[param] = "settings." + validationError.error;
      }
    },
    async saveSettings() {
      const isValidationOk = this.validateSaveSettings();
      if (!isValidationOk) {
        return;
      }
      this.loading.configureModule = true;
      const taskAction = "configure-module";

      // register to task error
      this.core.$root.$off(taskAction + "-aborted");
      this.core.$root.$once(taskAction + "-aborted", this.saveSettingsAborted);

      // register to task validation
      this.core.$root.$off(taskAction + "-validation-failed");
      this.core.$root.$once(
        taskAction + "-validation-failed",
        this.saveSettingsValidationFailed
      );

      // register to task completion
      this.core.$root.$off(taskAction + "-completed");
      this.core.$root.$once(
        taskAction + "-completed",
        this.saveSettingsCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.isLetsEncryptEnabled,
            domain: this.domain === "-" ? "" : this.domain,
            is_collabora: this.is_collabora,
            collabora_host: this.collabora_host,
            tls_verify_collabora: this.tls_verify_collabora,
            password: this.password
          },
          extra: {
            title: this.$t("settings.instance_configuration", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.configuring"),
          },
        })
      );
      const err = res[0];
      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    saveSettingsAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.core.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.host = config.host;
      this.isLetsEncryptEnabled = config.lets_encrypt;
      this.running = config.running;
      this.installed = config.installed;
      this.is_collabora = config.is_collabora;
      this.tls_verify_collabora = config.tls_verify_collabora;
      this.collabora_host = config.collabora_host;
      this.collabora_URL = config.array_collabora;
      this.loading.getConfiguration = false;
      this.domain = config.domain === "" ? "-" : config.domain;
      this.focusElement("host");
    },
    listUserDomainsCompleted(taskContext, taskResult) {
      const domains = taskResult.output;

      domains["domains"].forEach((element) => {
        const option = {
          name: element["name"],
          label: element["name"],
          value: element["name"],
        };
        this.domains.push(option);
      });
      //PUSH no domain option
      this.domains.unshift({
        name: "no_user_domain",
        label: this.$t("settings.no_user_domain"),
        value: "-"
      });
      this.loading.listUserDomains = false;
    },
    saveSettingsCompleted() {
      this.loading.configureModule = false;
      // reload configuration
      this.getConfiguration();
    }
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";

.cv-form .bx--form-item {
  margin-bottom: $spacing-06;
}
</style>