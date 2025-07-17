module MODLAND

# MODLAND.jl: Utilities for working with MODIS land grid and projections
# Provides functions to convert between latitude/longitude and MODIS sinusoidal projection,
# and to determine MODIS tile indices for given coordinates or polygons.


# Import required packages for geospatial operations and data handling
import ArchGDAL as AG
import ArchGDAL
import GeoDataFrames as GDF
import GeoFormatTypes as GFT
using DataFrames
using Rasters
import JSON


# Constants defining the boundaries of the MODIS sinusoidal projection (in meters)
UPPER_LEFT_X_METERS = -20015109.355798   # Westernmost x coordinate
UPPER_LEFT_Y_METERS = 10007554.677899    # Northernmost y coordinate
LOWER_RIGHT_X_METERS = 20015109.355798   # Easternmost x coordinate
LOWER_RIGHT_Y_METERS = -10007554.677899  # Southernmost y coordinate

# Size (width or height) of a MODIS tile in the sinusoidal projection (in meters)
TILE_SIZE_METERS = 1111950.5197665554

# Number of rows and columns in the MODIS land grid
TOTAL_ROWS = 18
TOTAL_COLUMNS = 36

# Coordinate reference systems (CRS) for WGS84 and MODIS sinusoidal projection
WGS84 = ProjString("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
SINUSOIDAL = ProjString("+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs")


"""
    latlon_to_sinusoidal(lat::Float64, lon::Float64) -> (x::Float64, y::Float64)

Convert latitude and longitude (in degrees, WGS84) to MODIS sinusoidal projection coordinates (in meters).

Arguments:
    lat::Float64: Latitude in degrees (-90 to 90)
    lon::Float64: Longitude in degrees (-180 to 180)

Returns:
    Tuple (x, y): Sinusoidal projection coordinates in meters

Throws:
    Error if latitude or longitude is out of bounds.
"""
function latlon_to_sinusoidal(lat::Float64, lon::Float64)::Tuple{Float64,Float64}
    # Validate latitude
    if lat < -90 || lat > 90
        error("latitude ($(lat)) out of bounds")
    end
    # Validate longitude
    if lon < -180 || lon > 180
        error("longitude ($(lon))) out of bounds")
    end

    # Create a point in WGS84 and reproject to sinusoidal
    point_latlon = AG.createpoint(lon, lat)
    point_sinusoidal = AG.reproject(point_latlon, WGS84, SINUSOIDAL)
    x = AG.getx(point_sinusoidal, 0)
    y = AG.gety(point_sinusoidal, 0)

    return x, y
end

export latlon_to_sinusoidal


"""
    sinusoidal_to_MODLAND(x::Float64, y::Float64) -> String

Given sinusoidal projection coordinates (x, y), return the MODIS land tile index (e.g., "h12v04")
that contains the point.

Arguments:
    x::Float64: Sinusoidal x coordinate (meters)
    y::Float64: Sinusoidal y coordinate (meters)

Returns:
    String: MODIS tile index in the format "hXXvYY"

Throws:
    Error if x or y is out of bounds for the MODIS grid.
"""
function sinusoidal_to_MODLAND(x::Float64, y::Float64)::String
    # Check if x is within the valid range
    if x < UPPER_LEFT_X_METERS || x > LOWER_RIGHT_X_METERS
        error("sinusoidal x coordinate ($(x)) out of bounds")
    end
    # Check if y is within the valid range
    if y < LOWER_RIGHT_Y_METERS || y > UPPER_LEFT_Y_METERS
        error("sinusoidal y ($(y))) coordinate out of bounds")
    end

    # Calculate horizontal (column) and vertical (row) indices
    horizontal_index = Int(floor((x - UPPER_LEFT_X_METERS) / TILE_SIZE_METERS))
    vertical_index = Int(floor((-1 * (y + LOWER_RIGHT_Y_METERS)) / TILE_SIZE_METERS))

    # Clamp indices to valid range if on the edge
    if horizontal_index == TOTAL_COLUMNS
        horizontal_index -= 1
    end
    if vertical_index == TOTAL_ROWS
        vertical_index -= 1
    end

    # Format as MODIS tile string (e.g., h12v04)
    tile = "h$(lpad(horizontal_index, 2, '0'))v$(lpad(vertical_index, 2, '0'))"
    return tile
end

export sinusoidal_to_MODLAND


"""
    latlon_to_MODLAND(lat, lon) -> String

Convert latitude and longitude (in degrees, WGS84) directly to the MODIS land tile index (e.g., "h12v04").

Arguments:
    lat: Latitude in degrees
    lon: Longitude in degrees

Returns:
    String: MODIS tile index in the format "hXXvYY"
"""
function latlon_to_MODLAND(lat, lon)
    # Convert lat/lon to sinusoidal coordinates
    x, y = latlon_to_sinusoidal(lat, lon)
    # Get MODIS tile index for the coordinates
    tile = sinusoidal_to_MODLAND(x, y)
    return tile
end

export latlon_to_MODLAND


"""
    MODLAND_tiles_in_polygon(poly::ArchGDAL.IGeometry{ArchGDAL.wkbPolygon25D}) -> Set{String}
    MODLAND_tiles_in_polygon(poly::AG.IGeometry{AG.wkbPolygon}) -> Set{String}

Given a polygon geometry, return the set of MODIS land tile indices that contain the polygon's vertices.
Note: Only the tiles containing the polygon's vertices are returned, not all tiles intersecting the polygon.

Arguments:
    poly: Polygon geometry (ArchGDAL.IGeometry)

Returns:
    Set{String}: Set of MODIS tile indices (e.g., Set(["h12v04", ...]))
"""
function MODLAND_tiles_in_polygon(poly::ArchGDAL.IGeometry{ArchGDAL.wkbPolygon25D})::Set{String}
    # Convert polygon to JSON, extract coordinates, and map to MODIS tiles
    Set([latlon_to_MODLAND(lat, lon) for (lon, lat) in JSON.parse(AG.toJSON(poly))["coordinates"][1]])
end

function MODLAND_tiles_in_polygon(poly::AG.IGeometry{AG.wkbPolygon})::Set{String}
    # Convert polygon to JSON, extract coordinates, and map to MODIS tiles
    Set([latlon_to_MODLAND(lat, lon) for (lon, lat) in JSON.parse(AG.toJSON(poly))["coordinates"][1]])
end

export MODLAND_tiles_in_polygon

end
