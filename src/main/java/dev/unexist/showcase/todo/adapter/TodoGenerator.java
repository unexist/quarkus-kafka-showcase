/**
 * @package Quarkus-Kafka-Showcase
 *
 * @file Todo resource
 * @copyright 2020-2021 Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the GNU GPLv3. See the file LICENSE for details.
 **/

package dev.unexist.showcase.todo.adapter;

import dev.unexist.showcase.todo.domain.todo.Todo;
import io.smallrye.mutiny.Multi;
import io.smallrye.reactive.messaging.kafka.Record;
import org.eclipse.microprofile.reactive.messaging.Outgoing;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.enterprise.context.ApplicationScoped;
import java.time.Duration;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;

@ApplicationScoped
public class TodoGenerator {
    private static final Logger LOGGER = LoggerFactory.getLogger(TodoGenerator.class);
    private static final int MILLIS = 500;

    private Random random = new Random();

    private List<Todo> todos = Collections.unmodifiableList(
            Arrays.asList(
                    new Todo("First", "Bla"),
                    new Todo("Second", "Bla-bla"),
                    new Todo("Third", "Bla-bla-bla"),
                    new Todo("Fourth", "Bla-bla-bla-bla"),
                    new Todo("Fifth", "Bla-bla-bla-bla-bla"),
                    new Todo("Sixth", "Bla-bla-bla-bla-bla-bla")
            )
    );

    @Outgoing("todo-titles")
    public Multi<Record<Integer, String>> generateTitles() {
        return Multi.createFrom().ticks().every(Duration.ofMillis(MILLIS))
                .onOverflow().drop()
                .map(tick -> {
                    int idx = random.nextInt(todos.size());
                    Todo todo = todos.get(idx);

                    LOGGER.info("Todo[{}]: {}: {}", idx, todo.getTitle(),
                            todo.getDescription());
                    return Record.of(idx, todo.getTitle());
                });
    }

    @Outgoing("todo-descriptions")
    public Multi<Record<Integer, String>> generateDescriptions() {
        return Multi.createFrom().ticks().every(Duration.ofMillis(MILLIS))
                .onOverflow().drop()
                .map(tick -> {
                    int idx = random.nextInt(todos.size());
                    Todo todo = todos.get(idx);

                    LOGGER.info("Todo[{}]: {}: {}", idx, todo.getTitle(),
                            todo.getDescription());
                    return Record.of(idx, todo.getDescription());
                });
    }
}
