export type Ok<T> = { success: true; data: T };
export type Err<E> = { success: false; error: E };
export type Result<T, E> = Ok<T> | Err<E>;
export type AsyncResult<T, E = Error> = Promise<Result<T, E>>;

export const Ok = <T>(data: T): Ok<T> => ({ success: true, data });
export const Err = <E>(error: E): Err<E> => ({ success: false, error });

export const isOk = <T, E>(result: Result<T, E>): result is Ok<T> =>
  result.success;
export const isErr = <T, E>(result: Result<T, E>): result is Err<E> =>
  !result.success;
