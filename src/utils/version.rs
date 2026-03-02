// Version parsing utilities — shared across detector, updater, bridge

/// Parse a dot-separated version string into a vector of numeric parts.
///
/// Examples:
///   "565.57.01" → [565, 57, 1]
///   "550.120"   → [550, 120]
///   "1.0.0"     → [1, 0, 0]
///   "abc"       → []
pub fn parse_version(v: &str) -> Vec<u32> {
    v.split('.').filter_map(|s| s.parse::<u32>().ok()).collect()
}

/// Compare two version strings numerically.
/// Returns positive if v1 > v2, negative if v1 < v2, 0 if equal.
///
/// Handles different-length versions by treating missing parts as 0.
pub fn compare_versions(v1: &str, v2: &str) -> i32 {
    let p1 = parse_version(v1);
    let p2 = parse_version(v2);

    for i in 0..p1.len().max(p2.len()) {
        let a = p1.get(i).copied().unwrap_or(0);
        let b = p2.get(i).copied().unwrap_or(0);
        if a > b {
            return 1;
        }
        if a < b {
            return -1;
        }
    }
    0
}

/// Sort a mutable slice of version strings in descending order.
pub fn sort_versions_desc(versions: &mut [String]) {
    versions.sort_by(|a, b| {
        let pa = parse_version(b); // reversed for descending
        let pb = parse_version(a);
        pa.cmp(&pb)
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── parse_version ───────────────────────────────────────────────

    #[test]
    fn parse_basic() {
        assert_eq!(parse_version("1.2.3"), vec![1, 2, 3]);
    }

    #[test]
    fn parse_nvidia_style() {
        assert_eq!(parse_version("565.57.01"), vec![565, 57, 1]);
    }

    #[test]
    fn parse_empty() {
        assert!(parse_version("").is_empty());
    }

    #[test]
    fn parse_non_numeric() {
        assert!(parse_version("abc").is_empty());
    }

    #[test]
    fn parse_single_component() {
        assert_eq!(parse_version("565"), vec![565]);
    }

    #[test]
    fn parse_leading_zeros() {
        // "01" parses as 1
        assert_eq!(parse_version("01.02.03"), vec![1, 2, 3]);
    }

    #[test]
    fn parse_mixed_alpha_numeric() {
        // "1.0.0-beta" → only numeric parts survive
        assert_eq!(parse_version("1.0.0-beta"), vec![1, 0]);
    }

    #[test]
    fn parse_four_components() {
        assert_eq!(parse_version("1.2.3.4"), vec![1, 2, 3, 4]);
    }

    // ── compare_versions ────────────────────────────────────────────

    #[test]
    fn compare_equal() {
        assert_eq!(compare_versions("1.0.0", "1.0.0"), 0);
    }

    #[test]
    fn compare_greater() {
        assert_eq!(compare_versions("2.0.0", "1.0.0"), 1);
        assert_eq!(compare_versions("565.57.01", "550.120"), 1);
    }

    #[test]
    fn compare_lesser() {
        assert_eq!(compare_versions("1.0.0", "2.0.0"), -1);
    }

    #[test]
    fn compare_different_lengths() {
        assert_eq!(compare_versions("1.0", "1.0.0"), 0);
        assert_eq!(compare_versions("1.0.1", "1.0"), 1);
    }

    #[test]
    fn compare_single_vs_triple() {
        assert_eq!(compare_versions("1", "1.0.0"), 0);
        assert_eq!(compare_versions("2", "1.9.9"), 1);
    }

    #[test]
    fn compare_empty_versions() {
        assert_eq!(compare_versions("", ""), 0);
        // Empty parses to [] so comparison with "1.0" yields -1
        assert_eq!(compare_versions("", "1.0"), -1);
    }

    // ── sort_versions_desc ──────────────────────────────────────────

    #[test]
    fn sort_desc_works() {
        let mut versions = vec![
            "535.183".to_string(),
            "565.57.01".to_string(),
            "550.120".to_string(),
        ];
        sort_versions_desc(&mut versions);
        assert_eq!(versions[0], "565.57.01");
        assert_eq!(versions[1], "550.120");
        assert_eq!(versions[2], "535.183");
    }

    #[test]
    fn sort_desc_single() {
        let mut versions = vec!["550.120".to_string()];
        sort_versions_desc(&mut versions);
        assert_eq!(versions[0], "550.120");
    }

    #[test]
    fn sort_desc_empty() {
        let mut versions: Vec<String> = vec![];
        sort_versions_desc(&mut versions);
        assert!(versions.is_empty());
    }

    #[test]
    fn sort_desc_equal_versions() {
        let mut versions = vec!["1.0.0".to_string(), "1.0.0".to_string()];
        sort_versions_desc(&mut versions);
        assert_eq!(versions.len(), 2);
    }
}
