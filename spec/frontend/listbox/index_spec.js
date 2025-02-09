import { nextTick } from 'vue';
import { getAllByRole, getByRole, getByTestId } from '@testing-library/dom';
import { GlDropdown, GlListbox } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import { initListbox, parseAttributes } from '~/listbox';
import { getFixture, setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/url_utility');

const fixture = getFixture('listbox/redirect_listbox.html');

const parsedAttributes = (() => {
  const div = document.createElement('div');
  div.innerHTML = fixture;
  return parseAttributes(div.firstChild);
})();

describe('initListbox', () => {
  let instance;

  afterEach(() => {
    if (instance) {
      instance.$destroy();
    }
  });

  const setup = (...args) => {
    instance = initListbox(...args);
  };

  it('returns null given no element', () => {
    setup();

    expect(instance).toBe(null);
  });

  it('throws given an invalid element', () => {
    expect(() => setup(document.body)).toThrow();
  });

  describe('given a valid element', () => {
    describe('when `glListboxForSortDropdowns` FF is enabled', () => {
      let onChangeSpy;

      const listbox = () => createWrapper(instance).findComponent(GlListbox);
      const findToggleButton = () => getByTestId(document.body, 'base-dropdown-toggle');
      const findSelectedItems = () => getAllByRole(document.body, 'option', { selected: true });

      beforeEach(async () => {
        window.gon.features = { glListboxForSortDropdowns: true };
        setHTMLFixture(fixture);
        onChangeSpy = jest.fn();
        setup(document.querySelector('.js-redirect-listbox'), { onChange: onChangeSpy });

        await nextTick();
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('returns an instance', () => {
        expect(instance).not.toBe(null);
      });

      it('renders button with selected item text', () => {
        expect(findToggleButton().textContent.trim()).toBe('Bar');
      });

      it('has the correct item selected', () => {
        const selectedItems = findSelectedItems();
        expect(selectedItems).toHaveLength(1);
        expect(selectedItems[0].textContent.trim()).toBe('Bar');
      });

      it('applies additional classes from the original element', () => {
        expect(instance.$el.classList).toContain('test-class-1', 'test-class-2');
      });

      describe.each(parsedAttributes.items)('selecting an item', (item) => {
        beforeEach(async () => {
          listbox().vm.$emit('select', item.value);
          await nextTick();
        });

        it('calls the onChange callback with the item', () => {
          expect(onChangeSpy).toHaveBeenCalledWith(item);
        });

        it('updates the toggle button text', () => {
          expect(findToggleButton().textContent.trim()).toBe(item.text);
        });

        it('marks the item as selected', () => {
          const selectedItems = findSelectedItems();
          expect(selectedItems).toHaveLength(1);
          expect(selectedItems[0].textContent.trim()).toBe(item.text);
        });
      });

      it('passes the "right" prop through to the underlying component', () => {
        expect(listbox().props('right')).toBe(parsedAttributes.right);
      });
    });

    describe('when `glListboxForSortDropdowns` FF is disabled', () => {
      let onChangeSpy;

      const ITEM_ROLE = 'menuitem';
      const dropdown = () => createWrapper(instance).findComponent(GlDropdown);

      const findToggleButton = () => document.body.querySelector('.gl-dropdown-toggle');
      const findItem = (text) => getByRole(document.body, ITEM_ROLE, { name: text });
      const findItems = () => getAllByRole(document.body, ITEM_ROLE);
      const findSelectedItems = () =>
        findItems().filter(
          (item) =>
            !item
              .querySelector('.gl-new-dropdown-item-check-icon')
              .classList.contains('gl-visibility-hidden'),
        );
      beforeEach(async () => {
        window.gon.features = { glListboxForSortDropdowns: false };
        setHTMLFixture(fixture);
        onChangeSpy = jest.fn();
        setup(document.querySelector('.js-redirect-listbox'), { onChange: onChangeSpy });

        await nextTick();
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('returns an instance', () => {
        expect(instance).not.toBe(null);
      });

      it('renders button with selected item text', () => {
        expect(findToggleButton().textContent.trim()).toBe('Bar');
      });

      it('has the correct item selected', () => {
        const selectedItems = findSelectedItems();
        expect(selectedItems).toHaveLength(1);
        expect(selectedItems[0].textContent.trim()).toBe('Bar');
      });

      it('applies additional classes from the original element', () => {
        expect(instance.$el.classList).toContain('test-class-1', 'test-class-2');
      });

      describe.each(parsedAttributes.items)('selecting an item', (item) => {
        beforeEach(async () => {
          findItem(item.text).click();
          await nextTick();
        });

        it('calls the onChange callback with the item', () => {
          expect(onChangeSpy).toHaveBeenCalledWith(item);
        });

        it('updates the toggle button text', () => {
          expect(findToggleButton().textContent.trim()).toBe(item.text);
        });

        it('marks the item as selected', () => {
          const selectedItems = findSelectedItems();
          expect(selectedItems).toHaveLength(1);
          expect(selectedItems[0].textContent.trim()).toBe(item.text);
        });
      });

      it('passes the "right" prop through to the underlying component', () => {
        expect(dropdown().props('right')).toBe(parsedAttributes.right);
      });
    });
  });
});
