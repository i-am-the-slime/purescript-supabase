// Pure builder transforms (Fn)

export const fromImpl = (client, table) => client.from(table);

export const schemaImpl = (schemaName, client) => client.schema(schemaName);

export const deleteImpl = (queryBuilder, _unit) => queryBuilder.delete();

export const updateImpl = (queryBuilder, record) => queryBuilder.update(record);

export const upsertImpl = (queryBuilder, values) => queryBuilder.upsert(values);

export const upsertWithImpl = (values, options, queryBuilder) =>
  queryBuilder.upsert(values, options);

export const selectImpl = (queryBuilder, projection) =>
  queryBuilder.select(projection);

export const selectColumnsWithCountImpl = (queryBuilder, projection, count) =>
  queryBuilder.select(projection, { count });

export const eqImpl = (key, value, builder) => builder.eq(key, value);

export const orImpl = (conditions, builder) => builder.or(conditions.join(","));

export const inImpl = (key, values, builder) => builder.in(key, values);

export const neqImpl = (key, value, builder) => builder.neq(key, value);

export const gtImpl = (key, value, builder) => builder.gt(key, value);

export const gteImpl = (key, value, builder) => builder.gte(key, value);

export const ltImpl = (key, value, builder) => builder.lt(key, value);

export const lteImpl = (key, value, builder) => builder.lte(key, value);

export const likeImpl = (key, pattern, builder) => builder.like(key, pattern);

export const ilikeImpl = (key, pattern, builder) => builder.ilike(key, pattern);

export const isImpl = (key, value, builder) => builder.is(key, value);

export const notImpl = (column, filterOperatorAndValue, builder) => builder.not(column, filterOperatorAndValue);

export const containsImpl = (key, value, builder) => builder.contains(key, value);

export const containedByImpl = (key, value, builder) => builder.containedBy(key, value);

export const overlapsImpl = (key, value, builder) => builder.overlaps(key, value);

export const textSearchImpl = (column, query, options, builder) =>
  builder.textSearch(column, query, options);

export const orderImpl = (column, builder) => builder.order(column);

export const orderWithImpl = (column, options, builder) =>
  builder.order(column, options);

export const limitImpl = (count, builder) => builder.limit(count);

export const csvImpl = (builder) => builder.csv();

export const insertImpl = (queryBuilder, values) => queryBuilder.insert(values);

export const rpcImpl = (client, name) => client.rpc(name);

export const rpcWithImpl = (client, name, params) => client.rpc(name, params);

// Effectful terminal operations (EffectFn)

export const runImpl = (filterBuilder) => filterBuilder;

export const singleImpl = (filterBuilder) => filterBuilder.single();

export const maybeSingleImpl = (filterBuilder) => filterBuilder.maybeSingle();

export const rangeImpl = (from, to, filterBuilder) => filterBuilder.range(from, to);
