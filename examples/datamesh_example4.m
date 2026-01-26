%% This is an exemplar script for using the Oceanum Datamesh API in MATLAB
clc

% Add the parent directory to path so we can access the +oceanum package
addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% You can set your Datamesh token by directly passing it into the connector
% or by setting it in your enviroment using:
% setenv("DATAMESH_TOKEN", "your_token")
token = getenv("DATAMESH_TOKEN");
conn = oceanum.datamesh.Connector(token);

%% Find a datasource to load in
catalog = conn.get_catalog("oceanum 1km");
disp(catalog)

%% Check datasource
datasource = conn.get_datasource("oceanum_wave_nz1km_nz17_era5_spec");
disp(datasource)
disp(datasource.variables)
disp(datasource.description)

%% Create query
query = struct("datasource", "oceanum_wave_nz1km_nz17_era5_spec", ...
                "variables", ["dpt", "lon", "lat","wspd"]);
data = conn.query(query);

%% Clean data

dpt = data.data_vars.dpt.data;
wspd = data.data_vars.wspd.data;
time = datetime(data.coords.time.data, ...
    'InputFormat', 'yyyy-MM-dd''T''HH:mm:ssZ', ...
    'TimeZone','UTC');
lon = data.coords.lon.data;
lat = data.coords.lat.data;

%% Visualize the data
figure
boxplot([wspd(:,1), wspd(:,45)], {'Site 1','Site 45'})
ylabel('Daily mean wind speed')

%% plot wind speed at specific times
day = 398833;  % try a few values

figure
scatter(lon, lat, 80, wspd(day,:).', 'filled')
colorbar
xlabel('Longitude')
ylabel('Latitude')
title(sprintf('Wind speed at %s', string(time(tidx))))
axis equal
grid on


