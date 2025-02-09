import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BranchRule, {
  i18n,
} from '~/projects/settings/repository/branch_rules/components/branch_rule.vue';
import { branchRuleProvideMock, branchRulePropsMock } from '../mock_data';

describe('Branch rule', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BranchRule, {
      provide: branchRuleProvideMock,
      propsData: { ...branchRulePropsMock, ...props },
    });
  };

  const findDefaultBadge = () => wrapper.findByText(i18n.defaultLabel);
  const findProtectedBadge = () => wrapper.findByText(i18n.protectedLabel);
  const findBranchName = () => wrapper.findByText(branchRulePropsMock.name);
  const findProtectionDetailsList = () => wrapper.findByRole('list');
  const findProtectionDetailsListItems = () => wrapper.findAllByRole('listitem');
  const findDetailsButton = () => wrapper.findByText(i18n.detailsButtonLabel);

  beforeEach(() => createComponent());

  it('renders the branch name', () => {
    expect(findBranchName().exists()).toBe(true);
  });

  describe('badges', () => {
    it('renders both default and protected badges', () => {
      expect(findDefaultBadge().exists()).toBe(true);
      expect(findProtectedBadge().exists()).toBe(true);
    });

    it('does not render default badge if isDefault is set to false', () => {
      createComponent({ isDefault: false });
      expect(findDefaultBadge().exists()).toBe(false);
    });

    it('does not render protected badge if isProtected is set to false', () => {
      createComponent({ isProtected: false });
      expect(findProtectedBadge().exists()).toBe(false);
    });
  });

  it('does not render the protection details list of no details are present', () => {
    createComponent({ approvalDetails: null });
    expect(findProtectionDetailsList().exists()).toBe(false);
  });

  it('renders the protection details list items', () => {
    expect(findProtectionDetailsListItems().at(0).text()).toBe(
      branchRulePropsMock.approvalDetails[0],
    );
    expect(findProtectionDetailsListItems().at(1).text()).toBe(
      branchRulePropsMock.approvalDetails[1],
    );
  });

  it('renders a detail button with the correct href', () => {
    expect(findDetailsButton().attributes('href')).toBe(
      `${branchRuleProvideMock.branchRulesPath}?branch=${branchRulePropsMock.name}`,
    );
  });
});
