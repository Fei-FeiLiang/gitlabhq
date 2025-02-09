<script>
import { GlSprintf, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { getParameterByName } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import branchRulesQuery from '../../queries/branch_rules_details.query.graphql';
import Protection from './protection.vue';
import {
  I18N,
  ALL_BRANCHES_WILDCARD,
  BRANCH_PARAM_NAME,
  WILDCARDS_HELP_PATH,
  PROTECTED_BRANCHES_HELP_PATH,
} from './constants';

const wildcardsHelpDocLink = helpPagePath(WILDCARDS_HELP_PATH);
const protectedBranchesHelpDocLink = helpPagePath(PROTECTED_BRANCHES_HELP_PATH);

export default {
  name: 'RuleView',
  i18n: I18N,
  wildcardsHelpDocLink,
  protectedBranchesHelpDocLink,
  components: { Protection, GlSprintf, GlLink, GlLoadingIcon },
  inject: {
    projectPath: {
      default: '',
    },
    protectedBranchesPath: {
      default: '',
    },
  },
  apollo: {
    project: {
      query: branchRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update({ project: { branchRules } }) {
        this.branchProtection = branchRules.nodes.find(
          (rule) => rule.name === this.branch,
        )?.branchProtection;
      },
    },
  },
  data() {
    return {
      branch: getParameterByName(BRANCH_PARAM_NAME),
      branchProtection: {},
    };
  },
  computed: {
    forcePushDescription() {
      return this.branchProtection?.allowForcePush
        ? this.$options.i18n.allowForcePushDescription
        : this.$options.i18n.disallowForcePushDescription;
    },
    mergeAccessLevels() {
      const { mergeAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(mergeAccessLevels);
    },
    pushAccessLevels() {
      const { pushAccessLevels } = this.branchProtection || {};
      return this.getAccessLevels(pushAccessLevels);
    },
    allowedToMergeHeader() {
      return sprintf(this.$options.i18n.allowedToMergeHeader, {
        total: this.mergeAccessLevels.total,
      });
    },
    allowedToPushHeader() {
      return sprintf(this.$options.i18n.allowedToPushHeader, {
        total: this.pushAccessLevels.total,
      });
    },
    allBranches() {
      return this.branch === ALL_BRANCHES_WILDCARD;
    },
    allBranchesLabel() {
      return this.$options.i18n.allBranches;
    },
    branchTitle() {
      return this.allBranches
        ? this.$options.i18n.targetBranch
        : this.$options.i18n.branchNameOrPattern;
    },
  },
  methods: {
    getAccessLevels(accessLevels = {}) {
      const total = accessLevels.edges?.length;
      const accessLevelTypes = { total, users: [], groups: [], roles: [] };

      accessLevels.edges?.forEach(({ node }) => {
        if (node.user) {
          const src = node.user.avatarUrl;
          accessLevelTypes.users.push({ src, ...node.user });
        } else if (node.group) {
          accessLevelTypes.groups.push(node);
        } else {
          accessLevelTypes.roles.push(node);
        }
      });

      return accessLevelTypes;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="$apollo.loading" />
  <div v-else-if="!branchProtection">{{ $options.i18n.noData }}</div>
  <div v-else>
    <strong data-testid="branch-title">{{ branchTitle }}</strong>
    <p v-if="!allBranches" class="gl-mb-3 gl-text-gray-400">
      <gl-sprintf :message="$options.i18n.wildcardsHelpText">
        <template #link="{ content }">
          <gl-link :href="$options.wildcardsHelpDocLink">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>

    <div v-if="allBranches" class="gl-mt-2" data-testid="branch">
      {{ allBranchesLabel }}
    </div>
    <code v-else class="gl-mt-2" data-testid="branch">{{ branch }}</code>

    <h4 class="gl-mb-1 gl-mt-5">{{ $options.i18n.protectBranchTitle }}</h4>
    <gl-sprintf :message="$options.i18n.protectBranchDescription">
      <template #link="{ content }">
        <gl-link :href="$options.protectedBranchesHelpDocLink">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>

    <!-- Allowed to push -->
    <protection
      class="gl-mt-3"
      :header="allowedToPushHeader"
      :header-link-title="$options.i18n.manageProtectionsLinkTitle"
      :header-link-href="protectedBranchesPath"
      :roles="pushAccessLevels.roles"
      :users="pushAccessLevels.users"
      :groups="pushAccessLevels.groups"
    />

    <!-- Force push -->
    <strong>{{ $options.i18n.forcePushTitle }}</strong>
    <p>{{ forcePushDescription }}</p>

    <!-- Allowed to merge -->
    <protection
      :header="allowedToMergeHeader"
      :header-link-title="$options.i18n.manageProtectionsLinkTitle"
      :header-link-href="protectedBranchesPath"
      :roles="mergeAccessLevels.roles"
      :users="mergeAccessLevels.users"
      :groups="mergeAccessLevels.groups"
    />

    <!-- Approvals -->
    <!-- Follow-up: add approval section (https://gitlab.com/gitlab-org/gitlab/-/issues/372362) -->

    <!-- Status checks -->
    <!-- Follow-up: add status checks section (https://gitlab.com/gitlab-org/gitlab/-/issues/372362) -->
  </div>
</template>
