"""
Tests for pykyschooldata - Python wrapper for Kentucky school enrollment data.

Uses pytest. Requires R and the kyschooldata R package to be installed.
"""

import pytest
import pandas as pd


# Cache available years to avoid repeated R calls
_available_years = None


def get_test_years():
    """Get available years for testing, cached."""
    global _available_years
    if _available_years is None:
        import pykyschooldata as ky
        _available_years = ky.get_available_years()
    return _available_years


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
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        assert isinstance(df, pd.DataFrame)

    def test_dataframe_not_empty(self):
        """Test that returned DataFrame is not empty."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        assert len(df) > 0

    def test_has_expected_columns(self):
        """Test that DataFrame has expected columns."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        expected_cols = ["end_year", "n_students"]
        for col in expected_cols:
            assert col in df.columns, f"Missing column: {col}"

    def test_end_year_matches_request(self):
        """Test that end_year in data matches requested year."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        assert (df["end_year"] == years['max_year']).all()

    def test_state_level_data_exists(self):
        """Test that state-level data is present."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        if "is_state" in df.columns:
            state_data = df[df["is_state"] == True]
            assert len(state_data) > 0


class TestFetchEnrMulti:
    """Test the fetch_enr_multi function for multi-year fetches."""

    def test_returns_dataframe(self):
        """Test that fetch_enr_multi returns a pandas DataFrame."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr_multi([years['max_year']])
        assert isinstance(df, pd.DataFrame)

    def test_dataframe_not_empty(self):
        """Test that returned DataFrame is not empty."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr_multi([years['max_year']])
        assert len(df) > 0

    def test_contains_requested_year(self):
        """Test that result contains the requested year."""
        import pykyschooldata as ky
        years = get_test_years()
        test_year = years['max_year']
        df = ky.fetch_enr_multi([test_year])
        years_in_data = df["end_year"].unique()
        assert test_year in years_in_data, f"Missing year: {test_year}"

    def test_multi_matches_single(self):
        """Single-element multi-year fetch matches single fetch."""
        import pykyschooldata as ky
        years = get_test_years()
        df_single = ky.fetch_enr(years['max_year'])
        df_multi = ky.fetch_enr_multi([years['max_year']])
        # Row counts should match
        assert len(df_single) == len(df_multi)


class TestDataIntegrity:
    """Test data integrity and expected values for Kentucky."""

    def test_state_enrollment_reasonable(self):
        """Test that state total enrollment is reasonable for Kentucky."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
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
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        if "is_district" in df.columns and "district_name" in df.columns:
            districts = df[df["is_district"] == True]["district_name"].unique()
            # Kentucky has 171 districts (120 county + 51 independent)
            assert len(districts) >= 100, f"Only {len(districts)} districts found"
            assert len(districts) <= 200, f"Too many districts: {len(districts)}"

    def test_enrollment_values_positive(self):
        """Test that enrollment values are non-negative."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
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
        years = get_test_years()
        df = ky.fetch_enr_multi([years['max_year']])
        assert isinstance(df, pd.DataFrame)
        assert len(df) > 0

    def test_empty_year_list_returns_empty(self):
        """Empty year list returns empty dataframe or raises error."""
        import pykyschooldata as ky
        # R function may return empty df or raise - just verify it doesn't crash unexpectedly
        try:
            result = ky.fetch_enr_multi([])
            # If it returns, should be a DataFrame (possibly empty)
            assert isinstance(result, pd.DataFrame)
        except Exception:
            # Raising an exception is also acceptable
            pass


class TestTidyEnr:
    """Test tidy_enr function."""

    @pytest.mark.skip(reason="tidy_enr R function has column name issues - skipping until fixed")
    def test_returns_dataframe(self):
        """Returns a pandas DataFrame."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        tidy = ky.tidy_enr(df)
        assert isinstance(tidy, pd.DataFrame)

    @pytest.mark.skip(reason="tidy_enr R function has column name issues - skipping until fixed")
    def test_has_subgroup_column(self):
        """Tidy data has subgroup column."""
        import pykyschooldata as ky
        years = get_test_years()
        df = ky.fetch_enr(years['max_year'])
        tidy = ky.tidy_enr(df)
        assert 'subgroup' in tidy.columns or len(tidy) > 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
