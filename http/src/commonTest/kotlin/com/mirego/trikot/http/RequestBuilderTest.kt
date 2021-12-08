package com.mirego.trikot.http

import kotlin.test.Test
import kotlin.test.assertEquals

class RequestBuilderTest {

    companion object {
        val BASE_URL = "https://www.url.com"
        val PATH = "/api"
    }

    @Test
    fun testBuildUrl() {

        val requestBuilder = RequestBuilder().also {
            it.baseUrl = BASE_URL
            it.path = PATH
        }

        assertEquals("https://www.url.com/api", requestBuilder.buildUrl())
    }

    @Test
    fun `given empty path when buildUrl then return base url`() {

        val requestBuilder = RequestBuilder().also {
            it.baseUrl = BASE_URL
        }

        assertEquals(BASE_URL, requestBuilder.buildUrl())
    }

    @Test
    fun `given empty baseUrl and path when buildUrl then return empty string`() {
        val requestBuilder = RequestBuilder()

        assertEquals("", requestBuilder.buildUrl())
    }

    @Test
    fun `given parameters when buildUrl then return url with encoded parameters`() {
        val requestBuilder = RequestBuilder().also {
            it.baseUrl = BASE_URL
            it.path = PATH
            it.parameters = mapOf(
                "param" to "value1",
                "paramWithSpace" to "value ABC",
                "jsonParam" to "{\"data\": [\"value1\",\"value2\",\"value3\"]}",
            )
        }

        assertEquals(
            "https://www.url.com/api?param=value1&paramWithSpace=value+ABC&jsonParam=%7B%22data%22%3A+%5B%22value1%22%2C%22value2%22%2C%22value3%22%5D%7D",
            requestBuilder.buildUrl()
        )
    }

    @Test
    fun `given path already contains parameters when buildUrl then return url with additional parameters encoded`() {
        val requestBuilder = RequestBuilder().also {
            it.baseUrl = BASE_URL
            it.path = "$PATH?foo=bar"
            it.parameters = mapOf(
                "param" to "value 1"
            )
        }

        assertEquals("https://www.url.com/api?foo=bar&param=value+1", requestBuilder.buildUrl())
    }
}
