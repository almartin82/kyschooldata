"""
Tests for pykyschooldata - Python wrapper for Kentucky school enrollment data.

Uses pytest. Requires R and the kyschooldata R package to be installed.
"""

import pytest
import pandas as pd


class TestImport:
    """Test that the package imports correctly."""

    def test_import_package(self):
        """Test basic package import."""
        import pykyschooldata as ky
        assert ky is not None

    def test_import_version(self):
        """Test that version is defined."""
        import pykyschooldata as ky
        assert hasattr(ky, "__version__")
        assert isinstance(ky.__version__, str)

    def test_import_functions(self):
        """Test that main functions are exported."""
        import pykyschooldata as ky
        assert hasattr(ky, "fetch_enr")
        assert hasattr(ky, "fetch_enr_multi")
        assert hasattr(ky, "get_available_years")
        assert callable(ky.fetch_enr)
        assert callable(ky.fetch_enr_multi)
        assert callable(ky.get_available_years)


class TestGetAvailableYears:
    """Test the get_available_years function."""

    def test_returns_dict(self):
        """Test that get_available_years returns a dictionary."""
        import pykyschooldata as ky
        years = ky.get_available_years()
        assert isinstance(years, dict)

    def test_has_required_keys(self):
        """Test that result has min_year and max_year keys."""
        import pykyschooldata as ky
        years = ky.get_available_years()
        assert "min_year" in years
        assert "max_year" in years

    def test_years_are_integers(self):
        """Test that year values are integers."""
        import pykyschooldata as ky
        years = ky.get_available_years()
        assert isinstance(years["min_year"], int)
        assert isinstance(years["max_year"], int)

    def test_year_range_reasonable(self):
        """Test that year range is reasonable for Kentucky data."""
        import pykyschooldata as ky
        years = ky.get_available_years()
        # Kentucky data goes back to at least 1997
        assert years["min_year"] <= 2000
        assert years["max_year"] >= 2020
        assert years["min_year"] < years["max_year"]


class TestFetchEnr:
    """Test the fetch_enr function for single year fetches."""

    def test_returns_dataframe(self):
        """Test that fetch_enr returns a pandas DataFrame."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        assert isinstance(df, pd.DataFrame)

    def test_dataframe_not_empty(self):
        """Test that returned DataFrame is not empty."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        assert len(df) > 0

    def test_has_expected_columns(self):
        """Test that DataFrame has expected columns."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        expected_cols = ["end_year", "n_students"]
        for col in expected_cols:
            assert col in df.columns, f"Missing column: {col}"

    def test_end_year_matches_request(self):
        """Test that end_year in data matches requested year."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        assert (df["end_year"] == 2024).all()

    def test_state_level_data_exists(self):
        """Test that state-level data is present."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        if "is_state" in df.columns:
            state_data = df[df["is_state"] == True]
            assert len(state_data) > 0


class TestFetchEnrMulti:
    """Test the fetch_enr_multi function for multi-year fetches."""

    def test_returns_dataframe(self):
        """Test that fetch_enr_multi returns a pandas DataFrame."""
        import pykyschooldata as ky
        df = ky.fetch_enr_multi([2023, 2024])
        assert isinstance(df, pd.DataFrame)

    def test_dataframe_not_empty(self):
        """Test that returned DataFrame is not empty."""
        import pykyschooldata as ky
        df = ky.fetch_enr_multi([2023, 2024])
        assert len(df) > 0

    def test_contains_all_requested_years(self):
        """Test that result contains all requested years."""
        import pykyschooldata as ky
        years = [2022, 2023, 2024]
        df = ky.fetch_enr_multi(years)
        years_in_data = df["end_year"].unique()
        for year in years:
            assert year in years_in_data, f"Missing year: {year}"

    def test_multi_year_has_more_rows(self):
        """Test that multiple years have more rows than single year."""
        import pykyschooldata as ky
        df_single = ky.fetch_enr(2024)
        df_multi = ky.fetch_enr_multi([2023, 2024])
        assert len(df_multi) > len(df_single)


class TestDataIntegrity:
    """Test data integrity and expected values for Kentucky."""

    def test_state_enrollment_reasonable(self):
        """Test that state total enrollment is reasonable for Kentucky."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        # Filter for state-level total enrollment
        if "is_state" in df.columns and "subgroup" in df.columns:
            state_total = df[
                (df["is_state"] == True) &
                (df["subgroup"] == "total_enrollment")
            ]
            if "grade_level" in df.columns:
                state_total = state_total[state_total["grade_level"] == "TOTAL"]
            if len(state_total) > 0:
                total = state_total["n_students"].iloc[0]
                # Kentucky has approximately 640,000 students
                assert 400_000 < total < 900_000, f"State enrollment {total} outside expected range"

    def test_district_count_reasonable(self):
        """Test that district count is reasonable for Kentucky."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        if "is_district" in df.columns and "district_name" in df.columns:
            districts = df[df["is_district"] == True]["district_name"].unique()
            # Kentucky has 171 districts (120 county + 51 independent)
            assert len(districts) >= 100, f"Only {len(districts)} districts found"
            assert len(districts) <= 200, f"Too many districts: {len(districts)}"

    def test_enrollment_values_positive(self):
        """Test that enrollment values are non-negative."""
        import pykyschooldata as ky
        df = ky.fetch_enr(2024)
        # n_students should be non-negative (may have NaN)
        valid_students = df["n_students"].dropna()
        assert (valid_students >= 0).all(), "Found negative enrollment values"


class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_historical_year(self):
        """Test fetching historical data (pre-2012)."""
        import pykyschooldata as ky
        years = ky.get_available_years()
        if years["min_year"] < 2012:
            df = ky.fetch_enr(2005)
            assert isinstance(df, pd.DataFrame)
            assert len(df) > 0

    def test_single_year_list(self):
        """Test fetch_enr_multi with single year list."""
        import pykyschooldata as ky
        df = ky.fetch_enr_multi([2024])
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0

    def test_consecutive_years(self):
        """Test fetching consecutive years."""
        import pykyschooldata as ky
        df = ky.fetch_enr_multi([2020, 2021, 2022])
        assert isinstance(df, pd.DataFrame)
        unique_years = df["end_year"].unique()
        assert len(unique_years) == 3
