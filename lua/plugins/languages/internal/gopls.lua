local M = {}

local analyses = {
    -- Staticcheck Quick Fixes
    QF1005 = true, -- Expand call to math.Pow (https://staticcheck.dev/docs/checks/#QF1005)
    QF1006 = true, -- Lift if+break into loop condition (https://staticcheck.dev/docs/checks/#QF1006)
    QF1007 = true, -- Merge conditional assignment into variable declaration (https://staticcheck.dev/docs/checks/#QF1007)
    QF1011 = true, -- Omit redundant type from variable declaration (https://staticcheck.dev/docs/checks/#QF1011)

    -- Staticcheck Simplifications
    S1002 = true, -- Omit comparison with boolean constant (https://staticcheck.dev/docs/checks/#S1002)
    S1005 = true, -- Drop unnecessary use of the blank identifier (https://staticcheck.dev/docs/checks/#S1005)
    S1006 = true, -- Use 'for { ... }' for infinite loops (https://staticcheck.dev/docs/checks/#S1006)
    S1008 = true, -- Simplify returning boolean expression (https://staticcheck.dev/docs/checks/#S1008)
    S1011 = true, -- Use a single append to concatenate two slices (https://staticcheck.dev/docs/checks/#S1011)
    S1016 = true, -- Use a type conversion instead of manually copying struct fields (https://staticcheck.dev/docs/checks/#S1016)
    S1021 = true, -- Merge variable declaration and assignment (https://staticcheck.dev/docs/checks/#S1021)
    S1025 = true, -- Don't use fmt.Sprintf("%s", x) unnecessarily (https://staticcheck.dev/docs/checks/#S1025)
    S1029 = true, -- Range over the string directly (https://staticcheck.dev/docs/checks/#S1029)

    -- Staticcheck Advanced Analysis
    SA1000 = true, -- Invalid regular expression (https://staticcheck.dev/docs/checks/#SA1000)
    SA1002 = true, -- Invalid format in time.Parse (https://staticcheck.dev/docs/checks/#SA1002)
    SA1003 = true, -- Unsupported argument to functions in encoding/binary (https://staticcheck.dev/docs/checks/#SA1003)
    SA1007 = true, -- Invalid URL in net/url.Parse (https://staticcheck.dev/docs/checks/#SA1007)
    SA1010 = true, -- (*regexp.Regexp).FindAll called with n == 0, which will always return zero results (https://staticcheck.dev/docs/checks/#SA1010)
    SA1011 = true, -- Various methods in the 'strings' package expect valid UTF-8, but invalid input is provided (https://staticcheck.dev/docs/checks/#SA1011)
    SA1014 = true, -- Non-pointer value passed to Unmarshal or Decode (https://staticcheck.dev/docs/checks/#SA1014)
    SA1015 = true, -- Using time.Tick in a way that will leak. Consider using time.NewTicker, and only use time.Tick in tests, commands and endless functions (https://staticcheck.dev/docs/checks/#SA1015)
    SA1018 = true, -- strings.Replace called with n == 0, which does nothing (https://staticcheck.dev/docs/checks/#SA1018)
    SA1028 = true, -- sort.Slice can only be used on slices (https://staticcheck.dev/docs/checks/#SA1028)
    SA1032 = true, -- Wrong order of arguments to errors.Is (https://staticcheck.dev/docs/checks/#SA1032)
    SA4005 = true, -- Field assignment that will never be observed. Did you mean to use a pointer receiver? (https://staticcheck.dev/docs/checks/#SA4005)
    SA4006 = true, -- A value assigned to a variable is never read before being overwritten. Forgotten error check or dead code? (https://staticcheck.dev/docs/checks/#SA4006)
    SA4008 = true, -- The variable in the loop condition never changes, are you incrementing the wrong variable? (https://staticcheck.dev/docs/checks/#SA4008)
    SA4009 = true, -- A function argument is overwritten before its first use (https://staticcheck.dev/docs/checks/#SA4009)
    SA4010 = true, -- The result of append will never be observed anywhere (https://staticcheck.dev/docs/checks/#SA4010)
    SA4012 = true, -- Comparing a value against NaN even though no value is equal to NaN (https://staticcheck.dev/docs/checks/#SA4012)
    SA4015 = true, -- Calling functions like math.Ceil on floats converted from integers doesn't do anything useful (https://staticcheck.dev/docs/checks/#SA4015)
    SA4017 = true, -- Discarding the return values of a function without side effects, making the call pointless (https://staticcheck.dev/docs/checks/#SA4017)
    SA4018 = true, -- Self-assignment of variables (https://staticcheck.dev/docs/checks/#SA4018)
    SA4031 = true, -- Checking never-nil value against nil (https://staticcheck.dev/docs/checks/#SA4031)
    SA5002 = true, -- The empty for loop ('for {}') spins and can block the scheduler (https://staticcheck.dev/docs/checks/#SA5002)
    SA5005 = true, -- The finalizer references the finalized object, preventing garbage collection (https://staticcheck.dev/docs/checks/#SA5005)
    SA5007 = true, -- Infinite recursive call (https://staticcheck.dev/docs/checks/#SA5007)
    SA5012 = true, -- Passing odd-sized slice to function expecting even size (https://staticcheck.dev/docs/checks/#SA5012)
    SA6000 = true, -- Using regexp.Match or related in a loop, should use regexp.Compile (https://staticcheck.dev/docs/checks/#SA6000)
    SA6001 = true, -- Missing an optimization opportunity when indexing maps by byte slices (https://staticcheck.dev/docs/checks/#SA6001)
    SA9001 = true, -- Defers in range loops may not run when you expect them to (https://staticcheck.dev/docs/checks/#SA9001)
    SA9005 = true, -- Trying to marshal a struct with no public fields nor custom marshaling (https://staticcheck.dev/docs/checks/#SA9005)
    SA9008 = true, -- else branch of a type assertion is probably not reading the right value (https://staticcheck.dev/docs/checks/#SA9008)

    -- Staticcheck Style Checks
    ST1005 = true, -- Incorrectly formatted error string (https://staticcheck.dev/docs/checks/#ST1005)
    ST1008 = true, -- A function's error value should be its last return value (https://staticcheck.dev/docs/checks/#ST1008)
    ST1013 = true, -- Should use constants for HTTP error codes, not magic numbers (https://staticcheck.dev/docs/checks/#ST1013)
    ST1015 = true, -- A switch's default case should be the first or last case (https://staticcheck.dev/docs/checks/#ST1015)
    ST1017 = true, -- Don't use Yoda conditions (https://staticcheck.dev/docs/checks/#ST1017)
    ST1020 = true, -- The documentation of an exported function should start with the function's name (https://staticcheck.dev/docs/checks/#ST1020)
    ST1021 = true, -- The documentation of an exported type should start with type's name (https://staticcheck.dev/docs/checks/#ST1021)
    ST1022 = true, -- The documentation of an exported variable or constant should start with variable's name (https://staticcheck.dev/docs/checks/#ST1022)
    ST1023 = true, -- Redundant type in variable declaration (https://staticcheck.dev/docs/checks/#ST1023)

    -- Optional Gopls & Modernizer Analyzers
    slicesdelete = true, -- replace append-based slice deletion with slices.Delete (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_slicesdelete)[cite: 1]
    fieldalignment = true, -- find structs that would use less memory if their fields were sorted (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/fieldalignment)[cite: 1]
    shadow = true, -- check for possible unintended shadowing of variables (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/shadow)[cite: 1]
    appendclipped = true, -- simplify append chains using slices.Concat (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_appendclipped)
    bloop = true, -- replace for-range over b.N with b.Loop (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_bloop)
    errorsastype = true, -- replace errors.As with errors.AsType[T] (https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/modernize#hdr-Analyzer_errorsastype)
}

--- @type vim.lsp.Config
M.lsp_config = {
    settings = {
        gopls = {
            semanticTokens = true,
            hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
            },
            analyses = analyses,
            staticcheck = true,
        },
    },
}

return M
