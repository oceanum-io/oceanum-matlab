# oceanum-matlab

MATLAB library for interacting with the [Oceanum.io platform](https://oceanum.io).

This is a MATLAB conversion of the [oceanum-python](../oceanum-python) library, providing read-only access to the Oceanum datamesh.

## Features

- Connect to the Oceanum datamesh API
- Browse and search the data catalog  
- Load datasources as MATLAB tables or NetCDF structures
- Execute OceanQL queries with filtering
- Internal staging for improved performance and size warnings
- Automatic session management  
- NetCDF support for dataset containers
- Query size limits with clear error messages
- Compatible with MATLAB R2022b and later
- Octave compatibility for basic operations

## Installation

1. Clone or download this repository
2. Add the `oceanum-matlab` directory to your MATLAB path:
   ```matlab
   addpath('/path/to/oceanum-matlab');
   ```

## Quick Start

```matlab
% Set your datamesh token (get from your Oceanum account)
setenv('DATAMESH_TOKEN', 'your-token-here');

% Create connection
connector = oceanum.datamesh.Connector();

% Browse catalog
catalog = connector.getCatalog('limit', 10);
disp(catalog);

% Load a datasource
data = connector.loadDatasource('datasource-id');

% Make a query
result = connector.query('datasource', 'datasource-id', 'limit', 1000);
```

## Documentation

The MATLAB API closely follows the Python library. For detailed documentation, see:
- [Python documentation](https://oceanum-python.readthedocs.io/) (API reference)
- [examples/basic_usage.m](examples/basic_usage.m) (MATLAB-specific examples)

## Main Classes

- **`oceanum.datamesh.Connector`** - Main class for API communication
- **`oceanum.datamesh.Catalog`** - Browse and search datasources  
- **`oceanum.datamesh.Datasource`** - Individual datasource metadata
- **`oceanum.datamesh.Query`** - Query builder for advanced filtering
- **`oceanum.datamesh.Stage`** - Internal query staging information  
- **`oceanum.datamesh.Session`** - Automatic session management

## Testing

Run the test suite:
```matlab
cd tests
run_tests()
```

Note: Integration tests require a valid `DATAMESH_TOKEN` environment variable.

## Limitations

Compared to the Python library, this MATLAB version:
- Is read-only (no write functionality)
- Has limited format support (Parquet tables and NetCDF structures)
- No async support (synchronous only)
- No lazy loading (fails on queries that are too large)
- No advanced data types (xarray, geopandas equivalents)

## Requirements

- MATLAB R2022b or later (for `arguments` blocks)
- Or GNU Octave 6.0+ (basic compatibility)

## License

Same license as the parent oceanum-python project.