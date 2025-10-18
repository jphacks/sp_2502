export type DefinedPatch<T extends object> = {
  [K in keyof T]?: Exclude<T[K], undefined>;
};

export const pickDefined = <T extends object>(o: T): DefinedPatch<T> => {
  const out = {} as DefinedPatch<T>;
  for (const k in o) {
    const v = (o as Record<string, unknown>)[k];
    if (v !== undefined) (out as Record<string, unknown>)[k] = v;
  }
  return out;
};
