/**
 * Copyright IBM Corporation 2016, 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#include "include/utils.h"

#include <string.h>

const char* get_method(http_parser* parser) {
    return http_method_str(parser->method);
}

unsigned int get_upgrade_value(http_parser* parser) {
    return parser->upgrade;
}

unsigned int get_status_code(http_parser* parser) {
    return parser->status_code;
}

int http_parser_parse_url_url (const char *buf, size_t buflen,
                               int is_connect, struct http_parser_url_url *u) {

    struct http_parser_url url;
    int res = http_parser_parse_url (buf, buflen,
                                     is_connect, &url);
    u->field_set = url.field_set;
    u->port = url.port;
    memcpy(u->field_data, url.field_data, sizeof(url.field_data));

    return res;
}

