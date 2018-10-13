--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Hakyll.Web.Pandoc
import           Text.Pandoc.Options
import qualified Data.Map as M
import           Data.Maybe

-- Deploy
config :: Configuration
config = defaultConfiguration
        {   deployCommand = "rsync -avz -e ssh ./_site/ /tmp"}

--------------------------------------------------------------------------------
markdownArticleFilter = fromRegex "posts/.*\\.markdown"

main :: IO ()
main = hakyll $ do
    match "posts/**/*.png" $ do
        route   idRoute
        compile copyFileCompiler

    -- static files to copy verbatim
    match (fromList ["feed/*", "CNAME"]) $ do
      route idRoute
      compile copyFileCompiler

    match "en/**" $ do
      route idRoute
      compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "js/**" $ do
        route idRoute
        compile copyFileCompiler

    match (fromList ["about.rst", "contact.rst"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" (mathCtx `mappend` defaultContext)
            >>= relativizeUrls

    match markdownArticleFilter $ do
        route $ setExtension "html"
        compile $ postCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll markdownArticleFilter
            let archiveContext =
                    listField "posts" archiveCtx (return posts) `mappend`
                    constField "title" "Archives" `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveContext
                >>= loadAndApplyTemplate "templates/default.html" postCtx
                >>= relativizeUrls

    create ["atom.xml"] $ do
        route $ constRoute "feed/atom.xml"
        compile $ do
            let feedCtx = postCtx `mappend` bodyField "description"

            posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots markdownArticleFilter "content"
            renderAtom myFeedConfiguration feedCtx posts

    -- TODO. This code is copy pasted from the atom. Look for a clever way to
    -- mege it
    create ["rss.xml"] $ do
        route $ constRoute "feed/rss.xml"
        compile $ do
            let feedCtx = postCtx `mappend` bodyField "description"

            posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots markdownArticleFilter "content"
            renderRss myFeedConfiguration feedCtx posts

    match "index.html" $ do
        route idRoute
        compile $ do
          posts <- recentFirst =<< loadAll markdownArticleFilter
          let indexContext =
                listField "posts" postCtx (return posts) `mappend`
                constField "title" "Home" `mappend`
                mathCtx `mappend`
                defaultContext

          getResourceBody
            >>= applyAsTemplate indexContext
            >>= loadAndApplyTemplate "templates/default.html" indexContext
            >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
myFeedConfiguration = FeedConfiguration {
    feedTitle = "Toni Cebrián"
    , feedDescription = "My personal blog where I talk mostly about programming, machine learning and other things"
    , feedAuthorName = "Toni Cebrián"
    , feedAuthorEmail = "toni.cebrian@gmail.com"
    , feedRoot = "http://www.tonicebrian.com"
}

--------------------------------------------------------------------------------
archiveCtx :: Context String
archiveCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    mathCtx `mappend`
    defaultContext

--------------------------------------------------------------------------------
mathCtx :: Context a
mathCtx = field "mathjax" $ \item -> do
    metadata <- getMetadata $ itemIdentifier item 
    return $ if isJust $ M.lookup "mathjax" metadata
                  then "<script type=\"text/javascript\" src=\"http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML\"></script>"
                  else ""

----------------------------------------------------------------------------------
postCompiler :: Compiler (Item String)
postCompiler = pandocCompilerWith defaultHakyllReaderOptions postWriterOptions

-- | Pandoc writer options for articles
--
postWriterOptions :: WriterOptions
postWriterOptions = defaultHakyllWriterOptions
    { writerHTMLMathMethod   = MathJax ""
    }

--------------------------------------------------------------------------------
postList :: ([Item String] -> Compiler [Item String]) -> Compiler String
postList sortFilter = do
    posts   <- sortFilter =<< loadAll "posts/*/*/*/*.markdown"
    itemTpl <- loadBody "templates/post-item.html"
    list    <- applyTemplateList itemTpl postCtx posts
    return list
