import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import PageComponent from '~/pdf/page/index.vue';

jest.mock('pdfjs-dist/webpack', () => {
  return { default: jest.requireActual('pdfjs-dist/build/pdf') };
});

describe('Page component', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the page when mounting', async () => {
    const testPage = {
      render: jest.fn().mockReturnValue({ promise: Promise.resolve() }),
      getViewport: jest.fn().mockReturnValue({}),
    };

    wrapper = mount(PageComponent, {
      propsData: {
        page: testPage,
        number: 1,
      },
    });

    await nextTick();

    expect(testPage.render).toHaveBeenCalledWith({
      canvasContext: wrapper.find('canvas').element.getContext('2d'),
      viewport: testPage.getViewport(),
    });
  });
});
