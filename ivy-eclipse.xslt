<?xml version="1.0" encoding="UTF-8"?>
<!--+=======================================================================+
    | Copyright 2014 USRZ.com and Pier Paolo Fumagalli                      |
    +- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
    | Licensed under the Apache License, Version 2.0 (the "License");       |
    | you may not use this file except in compliance with the License.      |
    | You may obtain a copy of the License at                               |
    |                                                                       |
    |  http://www.apache.org/licenses/LICENSE-2.0                           |
    |                                                                       |
    | Unless required by applicable law or agreed to in writing, software   |
    | distributed under the License is distributed on an "AS IS" BASIS,     |
    | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or       |
    | implied. See the License for the specific language governing          |
    | permissions and limitations under the License.                        |
    +=======================================================================+-->

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Make sure we encode this nicely -->
  <xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no"/>

  <!-- Start creating a normal Eclipse .classpath file (order is important) -->
  <xsl:template match="/">
    <classpath>
      <!-- Source directories and JDK container -->
    	<classpathentry kind="src" path="source/main" output=".eclipseout/main" />
    	<classpathentry kind="src" path="source/test" output=".eclipseout/test" />
    	<classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>

      <!-- Using the artifact report, configure all libraries -->
      <xsl:apply-templates select="/modules/module">
        <xsl:sort select="@organisation"/>
        <xsl:sort select="@name"/>
        <xsl:sort select="@rev"/>
      </xsl:apply-templates>

      <!-- Output directory -->
    	<classpathentry kind="output" path=".eclipseout/base" />
    </classpath>
  </xsl:template>

  <!-- Modules -->
  <xsl:template match="module">
    <xsl:apply-templates select="artifact[@type='bin']"/>
  </xsl:template>

  <!-- Artifacts -->
  <xsl:template match="artifact">
    <xsl:if test="@type='bin'">
      <xsl:if test="cache-location">
        <classpathentry kind="lib">

          <!-- If we have a "bin" artifact, it's the path of our library -->
          <xsl:attribute name="path">
            <xsl:value-of select="cache-location"/>
          </xsl:attribute>

          <xsl:variable name="name" select="@name"/>

          <!-- If we have a "src" artifact, link in the sources -->
          <xsl:if test="../artifact[@name=$name][@type='src']">
            <xsl:attribute name="sourcepath">
              <xsl:value-of select="../artifact[@name=$name][@type='src']/cache-location"/>
            </xsl:attribute>
          </xsl:if>

          <!-- If we have a "doc" artifact, add the JavaDOC attribute -->
          <xsl:if test="../artifact[@name=$name][@type='doc']">
            <attributes>
              <attribute name="javadoc_location" value="jar:file:{../artifact[@name=$name][@type='doc']/cache-location}!/"/>
            </attributes>
          </xsl:if>

          <!-- Warn about JUnit imports -->
          <xsl:if test="(../@name='junit') and (../@organisation='org.junit')">
        		<accessrules>
        			<accessrule kind="discouraged" pattern="junit/**"/>
        			<accessrule kind="discouraged" pattern="org/junit/**"/>
        		</accessrules>
          </xsl:if>

        </classpathentry>
      </xsl:if>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
