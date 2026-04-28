export const storageImpl = (client) => client.storage;

export const fromImpl = (storage, bucket) => storage.from(bucket);

export const uploadImpl = (bucket, filePath, file, fileOptions) =>
  bucket.upload(filePath, file, fileOptions);

export const downloadImpl = (bucket, filePath) =>
  bucket.download(filePath);

export const removeImpl = (bucket, filePaths) =>
  bucket.remove(filePaths);

export const createSignedUrlImpl = (bucket, filePath, expiry) =>
  bucket.createSignedUrl(filePath, expiry);

export const createSignedUrlsImpl = (bucket, filePaths, expiry) =>
  bucket.createSignedUrls(filePaths, expiry);

export const getPublicUrlImpl = (bucket, filePath) =>
  bucket.getPublicUrl(filePath);

export const listImpl = (bucket, prefix, options) =>
  bucket.list(prefix, options);

export const moveImpl = (bucket, fromPath, toPath) =>
  bucket.move(fromPath, toPath);

export const copyImpl = (bucket, fromPath, toPath) =>
  bucket.copy(fromPath, toPath);

export const existsImpl = (bucket, filePath) =>
  bucket.exists(filePath);
