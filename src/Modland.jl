module Modland

import ArchGDAL as AG
import ArchGDAL
import GeoDataFrames as GDF
import GeoFormatTypes as GFT
using DataFrames
using Rasters
using DimensionalData.Dimensions.LookupArrays
import JSON

# boundaries of sinusodial projection
UPPER_LEFT_X_METERS = -20015109.355798
UPPER_LEFT_Y_METERS = 10007554.677899
LOWER_RIGHT_X_METERS = 20015109.355798
LOWER_RIGHT_Y_METERS = -10007554.677899

# size across (width or height) of any equal-area sinusoidal target
TILE_SIZE_METERS = 1111950.5197665554

# boundaries of MODIS land grid
TOTAL_ROWS = 18
TOTAL_COLUMNS = 36

WGS84 = ProjString("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
SINUSOIDAL = ProjString("+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs")

export UPPER_LEFT_X_METERS, UPPER_LEFT_Y_METERS, LOWER_RIGHT_X_METERS, LOWER_RIGHT_Y_METERS, TILE_SIZE_METERS, TOTAL_ROWS, TOTAL_COLUMNS, WGS84, SINUSOIDAL


"""
    latlon_to_sinusoidal(lat::Float64, lon::Float64)::Tuple{Float64,Float64}

Convert latitude and longitude coordinates to sinusoidal projection coordinates.

# Arguments
- `lat::Float64`: Latitude in degrees.
- `lon::Float64`: Longitude in degrees.

# Returns
- `Tuple{Float64, Float64}`: Sinusoidal projection coordinates (x, y).
"""
function latlon_to_sinusoidal(lat::Float64, lon::Float64)::Tuple{Float64,Float64}
    # Check if latitude is within valid bounds
    if lat < -90 || lat > 90
        error("latitude ($(lat)) out of bounds")
    end

    # Check if longitude is within valid bounds
    if lon < -180 || lon > 180
        error("longitude ($(lon))) out of bounds")
    end

    # Create a point in latitude and longitude coordinates
    point_latlon = AG.createpoint(lon, lat)
    # Reproject the point from WGS84 to sinusoidal projection
    point_sinusoidal = AG.reproject(point_latlon, WGS84, SINUSOIDAL)
    # Extract the x coordinate from the reprojected point
    x = AG.getx(point_sinusoidal, 0)
    # Extract the y coordinate from the reprojected point
    y = AG.gety(point_sinusoidal, 0)

    # Return the sinusoidal coordinates as a tuple
    return x, y
end

export latlon_to_sinusoidal

"""
    sinusoidal_to_modland(x::Float64, y::Float64)::String

Convert sinusoidal projection coordinates to MODIS land tile indices.

# Arguments
- `x::Float64`: Sinusoidal x coordinate.
- `y::Float64`: Sinusoidal y coordinate.

# Returns
- `String`: MODIS land tile index in the format "hXXvYY".
"""
function sinusoidal_to_modland(x::Float64, y::Float64)::String
    # Check if the x coordinate is within the valid bounds of the sinusoidal projection
    if x < UPPER_LEFT_X_METERS || x > LOWER_RIGHT_X_METERS
        error("sinusoidal x coordinate ($(x)) out of bounds")
    end

    # Check if the y coordinate is within the valid bounds of the sinusoidal projection
    if y < LOWER_RIGHT_Y_METERS || y > UPPER_LEFT_Y_METERS
        error("sinusoidal y ($(y))) coordinate out of bounds")
    end

    # Calculate the horizontal tile index
    horizontal_index = Int(floor((x - UPPER_LEFT_X_METERS) / TILE_SIZE_METERS))
    # Calculate the vertical tile index
    vertical_index = Int(floor((-1 * (y + LOWER_RIGHT_Y_METERS)) / TILE_SIZE_METERS))

    # Adjust the horizontal index if it is at the boundary
    if horizontal_index == TOTAL_COLUMNS
        horizontal_index -= 1
    end

    # Adjust the vertical index if it is at the boundary
    if vertical_index == TOTAL_ROWS
        vertical_index -= 1
    end

    # Format the tile index as a string in the format "hXXvYY"
    tile = "h$(lpad(horizontal_index, 2, '0'))v$(lpad(vertical_index, 2, '0'))"

    # Return the formatted tile index
    return tile
end

export sinusoidal_to_modland

end