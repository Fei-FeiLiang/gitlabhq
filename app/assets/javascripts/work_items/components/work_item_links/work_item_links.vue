<script>
import { GlButton, GlIcon, GlAlert, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { produce } from 'immer';
import { s__ } from '~/locale';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { TYPE_WORK_ITEM } from '~/graphql_shared/constants';
import issueConfidentialQuery from '~/sidebar/queries/issue_confidential.query.graphql';
import { isMetaKey } from '~/lib/utils/common_utils';
import { setUrlParams, updateHistory } from '~/lib/utils/url_utility';

import { WIDGET_ICONS, WORK_ITEM_STATUS_TEXT, WIDGET_TYPE_HIERARCHY } from '../../constants';
import getWorkItemLinksQuery from '../../graphql/work_item_links.query.graphql';
import updateWorkItemMutation from '../../graphql/update_work_item.mutation.graphql';
import workItemQuery from '../../graphql/work_item.query.graphql';
import WorkItemDetailModal from '../work_item_detail_modal.vue';
import WorkItemLinkChild from './work_item_link_child.vue';
import WorkItemLinksForm from './work_item_links_form.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlAlert,
    GlLoadingIcon,
    WorkItemLinkChild,
    WorkItemLinksForm,
    WorkItemDetailModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectPath', 'iid'],
  props: {
    workItemId: {
      type: String,
      required: false,
      default: null,
    },
    issuableId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  apollo: {
    workItem: {
      query: getWorkItemLinksQuery,
      variables() {
        return {
          id: this.issuableGid,
        };
      },
      skip() {
        return !this.issuableId;
      },
      error(e) {
        this.error = e.message || this.$options.i18n.fetchError;
      },
    },
    parentIssue: {
      query: issueConfidentialQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data.workspace?.issuable;
      },
    },
  },
  data() {
    return {
      isShownAddForm: false,
      isOpen: true,
      activeChildId: null,
      activeToast: null,
      prefetchedWorkItem: null,
      error: undefined,
      parentIssue: null,
    };
  },
  computed: {
    confidential() {
      return this.parentIssue?.confidential || this.workItem?.confidential || false;
    },
    children() {
      return (
        this.workItem?.widgets.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)?.children
          .nodes ?? []
      );
    },
    canUpdate() {
      return this.workItem?.userPermissions.updateWorkItem || false;
    },
    // Only used for children for now but should be extended later to support parents and siblings
    isChildrenEmpty() {
      return this.children?.length === 0;
    },
    toggleIcon() {
      return this.isOpen ? 'chevron-lg-up' : 'chevron-lg-down';
    },
    toggleLabel() {
      return this.isOpen ? s__('WorkItem|Collapse tasks') : s__('WorkItem|Expand tasks');
    },
    issuableGid() {
      return this.issuableId ? convertToGraphQLId(TYPE_WORK_ITEM, this.issuableId) : null;
    },
    isLoading() {
      return this.$apollo.queries.workItem.loading;
    },
    childrenIds() {
      return this.children.map((c) => c.id);
    },
    childrenCountLabel() {
      return this.isLoading && this.children.length === 0 ? '...' : this.children.length;
    },
  },
  methods: {
    toggle() {
      this.isOpen = !this.isOpen;
    },
    showAddForm() {
      this.isOpen = true;
      this.isShownAddForm = true;
      this.$nextTick(() => {
        this.$refs.wiLinksForm.$refs.wiTitleInput?.$el.focus();
      });
    },
    hideAddForm() {
      this.isShownAddForm = false;
    },
    addChild(child) {
      const { defaultClient: client } = this.$apollo.provider.clients;
      this.toggleChildFromCache(child, child.id, client);
    },
    openChild(childItemId, e) {
      if (isMetaKey(e)) {
        return;
      }
      e.preventDefault();
      this.activeChildId = childItemId;
      this.$refs.modal.show();
      this.updateWorkItemIdUrlQuery(childItemId);
    },
    closeModal() {
      this.activeChildId = null;
      this.updateWorkItemIdUrlQuery(undefined);
    },
    handleWorkItemDeleted(childId) {
      const { defaultClient: client } = this.$apollo.provider.clients;
      this.toggleChildFromCache(null, childId, client);
      this.activeToast = this.$toast.show(s__('WorkItem|Task deleted'));
    },
    updateWorkItemIdUrlQuery(childItemId) {
      updateHistory({
        url: setUrlParams({ work_item_id: getIdFromGraphQLId(childItemId) }),
        replace: true,
      });
    },
    toggleChildFromCache(workItem, childId, store) {
      const sourceData = store.readQuery({
        query: getWorkItemLinksQuery,
        variables: { id: this.issuableGid },
      });

      const newData = produce(sourceData, (draftState) => {
        const widgetHierarchy = draftState.workItem.widgets.find(
          (widget) => widget.type === WIDGET_TYPE_HIERARCHY,
        );

        const index = widgetHierarchy.children.nodes.findIndex((child) => child.id === childId);

        if (index >= 0) {
          widgetHierarchy.children.nodes.splice(index, 1);
        } else {
          widgetHierarchy.children.nodes.push(workItem);
        }
      });

      store.writeQuery({
        query: getWorkItemLinksQuery,
        variables: { id: this.issuableGid },
        data: newData,
      });
    },
    async updateWorkItem(workItem, childId, parentId) {
      return this.$apollo.mutate({
        mutation: updateWorkItemMutation,
        variables: { input: { id: childId, hierarchyWidget: { parentId } } },
        update: (store) => this.toggleChildFromCache(workItem, childId, store),
      });
    },
    async undoChildRemoval(workItem, childId) {
      const { data } = await this.updateWorkItem(workItem, childId, this.issuableGid);

      if (data.workItemUpdate.errors.length === 0) {
        this.activeToast?.hide();
      }
    },
    async removeChild(childId) {
      const { data } = await this.updateWorkItem(null, childId, null);

      if (data.workItemUpdate.errors.length === 0) {
        this.activeToast = this.$toast.show(s__('WorkItem|Child removed'), {
          action: {
            text: s__('WorkItem|Undo'),
            onClick: this.undoChildRemoval.bind(this, data.workItemUpdate.workItem, childId),
          },
        });
      }
    },
    prefetchWorkItem(id) {
      this.prefetch = setTimeout(
        () =>
          this.$apollo.addSmartQuery('prefetchedWorkItem', {
            query: workItemQuery,
            variables: {
              id,
            },
            update: (data) => data.workItem,
          }),
        DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
      );
    },
    clearPrefetching() {
      clearTimeout(this.prefetch);
    },
  },
  i18n: {
    title: s__('WorkItem|Tasks'),
    fetchError: s__('WorkItem|Something went wrong when fetching tasks. Please refresh this page.'),
    emptyStateMessage: s__(
      'WorkItem|No tasks are currently assigned. Use tasks to break down this issue into smaller parts.',
    ),
    addChildButtonLabel: s__('WorkItem|Add'),
  },
  WIDGET_TYPE_TASK_ICON: WIDGET_ICONS.TASK,
  WORK_ITEM_STATUS_TEXT,
};
</script>

<template>
  <div
    class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100 gl-bg-gray-10 gl-mt-5"
    data-testid="work-item-links"
  >
    <div
      class="gl-px-5 gl-py-3 gl-display-flex gl-justify-content-space-between"
      :class="{ 'gl-border-b-1 gl-border-b-solid gl-border-b-gray-100': isOpen }"
    >
      <div class="gl-display-flex gl-flex-grow-1">
        <h5 class="gl-m-0 gl-line-height-24">{{ $options.i18n.title }}</h5>
        <span
          class="gl-display-inline-flex gl-align-items-center gl-line-height-24 gl-ml-3"
          data-testid="children-count"
        >
          <gl-icon :name="$options.WIDGET_TYPE_TASK_ICON" class="gl-mr-2 gl-text-secondary" />
          {{ childrenCountLabel }}
        </span>
      </div>
      <gl-button
        v-if="canUpdate"
        category="secondary"
        size="small"
        data-testid="toggle-add-form"
        @click="showAddForm"
      >
        {{ $options.i18n.addChildButtonLabel }}
      </gl-button>
      <div class="gl-border-l-1 gl-border-l-solid gl-border-l-gray-100 gl-pl-3 gl-ml-3">
        <gl-button
          category="tertiary"
          size="small"
          :icon="toggleIcon"
          :aria-label="toggleLabel"
          data-testid="toggle-links"
          @click="toggle"
        />
      </div>
    </div>
    <gl-alert v-if="error && !isLoading" variant="danger" @dismiss="error = undefined">
      {{ error }}
    </gl-alert>
    <div
      v-if="isOpen"
      class="gl-bg-gray-10 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
      :class="{ 'gl-p-5 gl-pb-3': !error }"
      data-testid="links-body"
    >
      <gl-loading-icon v-if="isLoading" color="dark" class="gl-my-3" />

      <template v-else>
        <div v-if="isChildrenEmpty && !isShownAddForm && !error" data-testid="links-empty">
          <p class="gl-mt-3 gl-mb-4">
            {{ $options.i18n.emptyStateMessage }}
          </p>
        </div>
        <work-item-links-form
          v-if="isShownAddForm"
          ref="wiLinksForm"
          data-testid="add-links-form"
          :issuable-gid="issuableGid"
          :children-ids="childrenIds"
          :parent-confidential="confidential"
          @cancel="hideAddForm"
          @addWorkItemChild="addChild"
        />
        <work-item-link-child
          v-for="child in children"
          :key="child.id"
          :project-path="projectPath"
          :can-update="canUpdate"
          :issuable-gid="issuableGid"
          :child-item="child"
          @click="openChild"
          @mouseover="prefetchWorkItem"
          @mouseout="clearPrefetching"
          @remove="removeChild"
        />
        <work-item-detail-modal
          ref="modal"
          :work-item-id="activeChildId"
          @close="closeModal"
          @workItemDeleted="handleWorkItemDeleted(activeChildId)"
        />
      </template>
    </div>
  </div>
</template>
