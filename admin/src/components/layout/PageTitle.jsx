import { createContext, useContext, useEffect, useState } from 'react';

const PageTitleContext = createContext({ title: '', subtitle: '', set: () => {} });

export function PageTitleProvider({ children }) {
  const [state, setState] = useState({ title: '', subtitle: '' });
  return (
    <PageTitleContext.Provider value={{ ...state, set: setState }}>{children}</PageTitleContext.Provider>
  );
}

/** Sets the heading shown in the green banner above the page content. */
export function usePageTitle(title, subtitle = '') {
  const { set } = useContext(PageTitleContext);
  useEffect(() => {
    set({ title, subtitle });
    document.title = `${title} | WellnessHabitTrack Admin`;
  }, [title, subtitle, set]);
}

export function usePageTitleState() {
  return useContext(PageTitleContext);
}
