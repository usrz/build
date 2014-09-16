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
  <xsl:strip-space elements="*" />
  <xsl:output method="xml"
              encoding="UTF-8"
              omit-xml-declaration="no"
              indent="yes"/>

  <!-- The variable for our URLs -->
  <xsl:param name="src"/>
  <xsl:param name="doc"/>
  <xsl:param name="bin"/>

  <!-- Separate XML declaration from root node -->
  <xsl:template match="/">
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates select="ivy-module"/>
  </xsl:template>

  <!-- Copy everything -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Update URLs for download -->
  <xsl:template match="/ivy-module/publications/artifact[@type='src']">
    <xsl:call-template name="artifact"><xsl:with-param name="url" select="$src"/></xsl:call-template>
  </xsl:template>
  <xsl:template match="/ivy-module/publications/artifact[@type='doc']">
    <xsl:call-template name="artifact"><xsl:with-param name="url" select="$doc"/></xsl:call-template>
  </xsl:template>
  <xsl:template match="/ivy-module/publications/artifact[@type='bin']">
    <xsl:call-template name="artifact"><xsl:with-param name="url" select="$bin"/></xsl:call-template>
  </xsl:template>

  <xsl:template name="artifact">
    <xsl:param name="url"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="$url">
        <xsl:attribute name="url">
          <xsl:value-of select="$url"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
