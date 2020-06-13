import React from "react"

import Layout from "../components/layout"
import SEO from "../components/seo"

const IndexPage = () => (
  <Layout>
    <SEO title="Home" />
    <h2>Todo:</h2>
    <ol>
      <li>Api call to create new game</li>
      <li>Api call to load active game</li>
      <li>Display game (Simple ASCII for now...)</li>
      <li>Api call to send ply and reload game</li>
    </ol>
  </Layout>
)

export default IndexPage
