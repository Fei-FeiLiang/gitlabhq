<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import Vue from 'vue';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import { createAlert } from '~/flash';
import { __ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import Store from '~/sidebar/stores/sidebar_store';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getMergeRequestReviewersQuery from '~/vue_shared/components/sidebar/queries/get_merge_request_reviewers.query.graphql';
import ReviewerTitle from './reviewer_title.vue';
import Reviewers from './reviewers.vue';

export const state = Vue.observable({
  issuable: {},
  loading: false,
  initialLoading: true,
});

export default {
  name: 'SidebarReviewers',
  components: {
    ReviewerTitle,
    Reviewers,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    mediator: {
      type: Object,
      required: true,
    },
    field: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
    issuableIid: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    issuable: {
      query: getMergeRequestReviewersQuery,
      variables() {
        return {
          iid: this.issuableIid,
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data.workspace?.issuable;
      },
      result() {
        this.initialLoading = false;
      },
      error() {
        createAlert({ message: __('An error occurred while fetching reviewers.') });
      },
    },
  },
  data() {
    return state;
  },
  computed: {
    relativeUrlRoot() {
      return gon.relative_url_root ?? '';
    },
    reviewers() {
      return this.issuable.reviewers?.nodes || [];
    },
    graphqlFetching() {
      return this.$apollo.queries.issuable.loading;
    },
    isLoading() {
      return this.loading || this.$apollo.queries.issuable.loading;
    },
    canUpdate() {
      return this.issuable.userPermissions?.updateMergeRequest || false;
    },
  },
  created() {
    this.store = new Store();

    this.removeReviewer = this.store.removeReviewer.bind(this.store);
    this.addReviewer = this.store.addReviewer.bind(this.store);
    this.removeAllReviewers = this.store.removeAllReviewers.bind(this.store);

    // Get events from deprecatedJQueryDropdown
    eventHub.$on('sidebar.removeReviewer', this.removeReviewer);
    eventHub.$on('sidebar.addReviewer', this.addReviewer);
    eventHub.$on('sidebar.removeAllReviewers', this.removeAllReviewers);
    eventHub.$on('sidebar.saveReviewers', this.saveReviewers);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.removeReviewer', this.removeReviewer);
    eventHub.$off('sidebar.addReviewer', this.addReviewer);
    eventHub.$off('sidebar.removeAllReviewers', this.removeAllReviewers);
    eventHub.$off('sidebar.saveReviewers', this.saveReviewers);
  },
  methods: {
    saveReviewers() {
      this.loading = true;

      this.mediator
        .saveReviewers(this.field)
        .then(() => {
          this.loading = false;
          refreshUserMergeRequestCounts();
          this.$apollo.queries.issuable.refetch();
        })
        .catch(() => {
          this.loading = false;
          return createAlert({
            message: __('Error occurred when saving reviewers'),
          });
        });
    },
    requestReview(data) {
      this.mediator.requestReview(data);
    },
  },
};
</script>

<template>
  <div>
    <reviewer-title
      :number-of-reviewers="reviewers.length"
      :loading="isLoading"
      :editable="canUpdate"
    />
    <reviewers
      v-if="!initialLoading"
      :root-path="relativeUrlRoot"
      :users="reviewers"
      :editable="canUpdate"
      :issuable-type="issuableType"
      @request-review="requestReview"
    />
  </div>
</template>
