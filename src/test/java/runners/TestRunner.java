package runners;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * Runs every feature under {@code classpath:features} in parallel.
 *
 * <ul>
 *   <li>{@code -Dtags=@smoke} filters by tag (comma = OR, e.g. {@code -Dtags=@smoke,@e2e}).</li>
 *   <li>{@code @bug} scenarios are excluded unless explicitly requested ({@code -Dtags=@bug}).</li>
 *   <li>{@code -Dthreads=N} sets the parallelism (default 5).</li>
 * </ul>
 */
class TestRunner {

    private static final String BUG_TAG = "@bug";

    @Test
    void runApiTests() {
        String tags = System.getProperty("tags", "").trim();
        int threads = Integer.parseInt(System.getProperty("threads", "5"));

        List<String> tagExpressions = new ArrayList<>();
        if (!tags.isEmpty()) {
            tagExpressions.add(tags);
        }
        if (!tags.contains(BUG_TAG)) {
            tagExpressions.add("~" + BUG_TAG);
        }

        Results results = Runner.path("classpath:features")
                .tags(tagExpressions.toArray(new String[0]))
                .outputJunitXml(true)
                .outputCucumberJson(true)
                .parallel(threads);

        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
