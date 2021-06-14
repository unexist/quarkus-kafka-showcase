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
import io.reactivex.Flowable;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.eclipse.microprofile.reactive.messaging.Outgoing;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.enterprise.context.ApplicationScoped;
import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Objects;
import java.util.Random;
import java.util.concurrent.TimeUnit;

@ApplicationScoped
public class TodoGenerator {
    private static final int MILLIS = 5000;
    private static final Logger LOGGER = LoggerFactory.getLogger(TodoGenerator.class);

    private final Random random = new Random();

    private List<Todo> todos = List.of(
            new Todo("First", "Bla"),
            new Todo("Second", "Bla-bla"),
            new Todo("Third", "Bla-bla-bla"),
            new Todo("Fourth", "Bla-bla-bla-bla"),
            new Todo("Fifth", "Bla-bla-bla-bla-bla"),
            new Todo("Sixth", "Bla-bla-bla-bla-bla-bla"));

    @Outgoing("todo-generator")
    public Flowable<KafkaRecord<Integer, GenericData.Record>> generate() throws IOException {
        Schema schemav1 = new Schema.Parser().parse(
                new File(Objects.requireNonNull(getClass().getClassLoader().getResource("avro/todov1.avsc")).getFile())
        );

        Schema schemav2 = new Schema.Parser().parse(
                new File(Objects.requireNonNull(getClass().getClassLoader().getResource("avro/todov2.avsc")).getFile())
        );

        return Flowable.interval(MILLIS, TimeUnit.MILLISECONDS)
                .onBackpressureDrop()
                .map(tick -> {
                    int idx = random.nextInt(this.todos.size());
                    Todo todo = todos.get(idx);

                    GenericData.Record record = new GenericData.Record(0 == idx % 2 ? schemav1 : schemav2);

                    record.put("title", todo.getTitle());
                    record.put("description", todo.getDescription());

                    return KafkaRecord.of(idx, record);
                });
    }
}
