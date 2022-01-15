# CS592 Human-AI Interaction Project

#### Goal: Add mixed-initiave interface design principles to natural language file search queries to reduce the time required to find files.

File searching can be an arduous task when the user does not remember the exact file details. With the current techniques, the user will have to search the file according to different parameters such as file type, name, date, or other metadata. This metadata can be difficult to remember and can require effort to share with the search engine. Often, metadata has to be filled into respective boxes rather than being parsed directly from the search request. We propose a tool that simplifies this task by allowing users to retrieve files with simple natural language queries.

The tool parses the query looking for phrases that relate to metadata so the user does not have to input them into specific fields. Additionally, the tool understands the context of words in order to convert words like "today" or "tomorrow" into the specific date that user means. The tool is accessible from Finder for quick access while already browsing for files. The tool presents all options that match the user’s query like a common file search application, along with files that our algorithm consider to be potential matches.

<img src="https://github.com/bbhardin/cs592-project/blob/main/images/example1.png" width="75%" />

The user's query is placed into the search box (1). After hitting search, the user can select the "Show/Hide Options" button to see the metadata that was parsed from the query (2), (3). The user can edit this metadata if it was parsed incorrectly and select "Search with these options" (4) to run the tool with the updated metadata. Up to 8 files that match the user's query are displayed below (5). A scrollable preview of the file is shown and the user can open the file or the file's location directly from the tool.

### <a href="https://github.com/bbhardin/cs592-project/blob/main/paper draft/Final Report.pdf">Draft of Project Report</a>
