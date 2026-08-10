
create catalog if not exists IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev_dep'));
create schema if not exists IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev_dep')||'.bronze');
create schema if not exists IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev_dep')||'.silver');
create schema if not exists IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev_dep')||'.gold');
create volume if not exists IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev_dep')||'.bronze.raw');
