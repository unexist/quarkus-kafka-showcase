/**
 * @package Quarkus-Kafka-Showcase
 *
 * @file Todo sink
 * @copyright 2020-2021 Christoph Kappel <christoph@unexist.dev>
 * @version $Id$
 *
 * This program can be distributed under the terms of the Apache License v2.0. See the file LICENSE for details.
 **/

package dev.unexist.showcase.todo.adapter;

import dev.unexist.showcase.todo.generated.avro.Todov1;
import dev.unexist.showcase.todo.generated.avro.Todov2;
import io.smallrye.reactive.messaging.kafka.KafkaRecord;
import org.apache.avro.specific.SpecificRecord;
import org.eclipse.microprofile.reactive.messaging.Incoming;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.enterprise.context.ApplicationScoped;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;

@ApplicationScoped
public class TodoSink {
    private static final Logger LOGGER = LoggerFactory.getLogger(TodoSink.class);

    @Incoming("todo-sink")
    public CompletionStage<Void> receive(KafkaRecord<Integer, SpecificRecord> message) {
        return CompletableFuture.runAsync(() -> {
            LOGGER.error("Read: {}: {}", message.getPayload().getSchema().getFullName(), message.getPayload());

            if (Todov1.getClassSchema().equals(message.getPayload().getSchema())) {
                Todov1 todov1 = (Todov1)message.getPayload();

                LOGGER.info("Got v1: title={}, description={}",
                        todov1.getTitle(), todov1.getDescription());

                message.ack();
            } else if (Todov2.getClassSchema().equals(message.getPayload().getSchema())) {
                Todov2 todov2 = (Todov2)message.getPayload();

                LOGGER.info("Got v2: title={}, description={}, done={}",
                        todov2.getTitle(), todov2.getDescription(), todov2.getDone());

                message.ack();
            }
        });
    }

}